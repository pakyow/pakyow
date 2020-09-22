# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/deep_dup"
require "pakyow/support/inspectable"

require_relative "result"

module Pakyow
  module Data
    # @api private
    class Proxy
      include Support::Inspectable
      inspectable :@source

      using Support::Refinements::Array::Ensurable

      using Support::DeepDup

      attr_reader :source, :proxied_calls, :nested_proxies, :app

      def initialize(source, subscribers, app)
        @source, @subscribers, @app = source, subscribers, app

        @proxied_calls = []
        @subscribable = true
        @nested_proxies = []
      end

      IVARS_TO_DUP = %i[@proxied_calls @nested_proxies].freeze

      def deep_dup
        duped = super

        IVARS_TO_DUP.each do |ivar|
          duped.instance_variable_set(ivar, duped.instance_variable_get(ivar).deep_dup)
        end

        duped
      end

      def method_missing(method_name, *args, &block)
        if @source.command?(method_name)
          duped_proxy = dup

          result = @source.command(method_name).call(*args) { |yielded_result|
            duped_proxy.instance_variable_set(:@source, yielded_result)
            yield duped_proxy if block_given?
          }

          if @source.respond_to?(:transaction) && @source.transaction?
            @source.on_commit do
              @subscribers.did_mutate(
                @source.source_name, args[0], result
              )
            end
          else
            @subscribers.did_mutate(
              @source.source_name, args[0], result
            )
          end

          duped_proxy
        elsif @source.query?(method_name) || @source.modifier?(method_name)
          duped_proxy = dup
          nested_calls = []

          new_source = if block_given? && @source.block_for_nested_source?(method_name)
            # In this case a block has been passed that would, without intervention,
            # be called in context of a source instance. We don't want that, since
            # it would provide full access to the underlying dataset. Instead the
            # exposed object should simply be another proxy.

            local_subscribers, local_app = @subscribers, @app
            @source.source_from_self.public_send(method_name, *args) {
              nested_proxy = Proxy.new(self, local_subscribers, local_app)
              nested_proxy.instance_variable_set(:@proxied_calls, nested_calls)
              nested_proxy_source = nested_proxy.instance_exec(&block).source

              finalized_nested_proxy = nested_proxy.dup
              finalized_nested_proxy.instance_variable_set(:@source, nested_proxy_source)

              duped_proxy.nested_proxies << finalized_nested_proxy

              nested_proxy_source
            }
          else
            working_source = @source.source_from_self.public_send(method_name, *args)

            working_source.included.each do |_, included_source|
              nested_proxy = Proxy.new(included_source, @subscribers, @app)
              duped_proxy.nested_proxies << nested_proxy
            end

            working_source
          end

          duped_proxy.instance_variable_set(:@source, new_source)
          duped_proxy.instance_variable_get(:@proxied_calls) << [
            method_name, args, nested_calls
          ]

          duped_proxy
        elsif Array.instance_methods.include?(method_name) && !@source.class.instance_methods.include?(method_name)
          build_result(
            @source.to_a.public_send(method_name, *args, &block),
            method_name, args
          )
        elsif @source.class.instance_methods.include?(method_name)
          build_result(
            @source.public_send(method_name, *args, &block),
            method_name, args
          )
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        return false if method_name == :marshal_dump || method_name == :marshal_load
        @source.command?(method_name) || @source.query?(method_name) || @source.modifier?(method_name) || @source.respond_to?(method_name, include_private)
      end

      def to_ary
        to_a
      end

      def to_json(*)
        @source.to_json
      end

      def subscribe(subscriber, handler:, payload: nil, &block)
        subscriptions = []

        if subscribable?
          subscription = {
            source: @source.source_name,
            ephemeral: @source.is_a?(Sources::Ephemeral),
            handler: handler,
            payload: payload,
            qualifications: qualifications,
            proxy: self
          }

          unless subscriptions.include?(subscription)
            subscriptions << subscription
          end

          @nested_proxies.each do |related_proxy|
            subscriptions.concat(
              related_proxy.subscribe_related(
                parent_source: @source,
                serialized_proxy: self,
                handler: handler,
                payload: payload
              )
            )
          end
        end

        @subscribers.register_subscriptions(subscriptions, subscriber: subscriber, &block)
      end

      def subscribe_related(parent_source:, serialized_proxy:, handler:, payload: nil)
        subscriptions = []

        if (association = parent_source.class.find_association_to_source(@source))
          parent_source.each do |parent_result|
            subscription = {
              source: @source.source_name,
              handler: handler,
              payload: payload,
              qualifications: qualifications.merge(
                association.associated_query_field => parent_result[association.query_field]
              ),
              proxy: serialized_proxy
            }

            unless subscriptions.include?(subscription)
              subscriptions << subscription
            end
          end
        else
          Pakyow.logger.error "tried to subscribe a related source, but we don't know how it's related"
        end

        @nested_proxies.each do |related_proxy|
          subscriptions.concat(
            related_proxy.subscribe_related(
              parent_source: @source,
              serialized_proxy: serialized_proxy,
              handler: handler,
              payload: payload
            )
          )
        end

        subscriptions
      end

      def unsubscribe
        subscribable(false)
      end

      def subscribable(boolean)
        tap do
          @subscribable = boolean
        end
      end

      def subscribable?
        @subscribable == true
      end

      def _dump(_)
        Marshal.dump(
          {
            app: @app,
            source: @source.is_a?(Sources::Ephemeral) ? @source : @source.source_name,
            proxied_calls: @proxied_calls
          }
        )
      end

      def self._load(state)
        state = Marshal.load(state)

        case state[:source]
        when Sources::Ephemeral
          ephemeral = state[:app].data.ephemeral(state[:source].source_name)
          ephemeral.instance_variable_set(:@source, state[:source])
          ephemeral
        else
          state[:app].data.public_send(state[:source]).apply(state[:proxied_calls])
        end
      end

      def qualifications
        @proxied_calls.inject(@source.qualifications) { |qualifications, proxied_call|
          qualifications_for_proxied_call = @source.class.qualifications(proxied_call[0]).dup

          # Populate argument qualifications with argument values.
          #
          qualifications_for_proxied_call.each do |qualification_key, qualification_value|
            if qualification_value.to_s.start_with?("__arg")
              arg_number = qualification_value.to_s.gsub(/[^0-9]/, "").to_i

              arg_value = proxied_call[1][arg_number]
              arg_value = case arg_value
              when Array
                arg_value.map { |each_value|
                  @source.class.attributes[qualification_key][each_value]
                }
              else
                @source.class.attributes[qualification_key][arg_value]
              end

              qualifications_for_proxied_call[qualification_key] = arg_value
            end
          end

          qualifications.merge(qualifications_for_proxied_call)
        }
      end

      # @api private
      def apply(proxied_calls)
        proxied_calls.inject(self) { |proxy, proxied_call|
          if proxied_call[2].any?
            proxy.public_send(proxied_call[0], *proxied_call[1]) do
              apply(proxied_call[2])
            end
          else
            proxy.public_send(proxied_call[0], *proxied_call[1])
          end
        }
      end

      private

      def build_result(value, method_name, args)
        if method_name.to_s.end_with?("?")
          value
        else
          Result.new(value, self, originating_method: method_name, originating_args: args)
        end
      end
    end
  end
end
