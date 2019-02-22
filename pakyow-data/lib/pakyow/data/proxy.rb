# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/deep_dup"
require "pakyow/support/inspectable"

require "pakyow/data/result"

module Pakyow
  module Data
    # @api private
    class Proxy
      include Support::Inspectable
      inspectable :@source

      using Support::Refinements::Array::Ensurable

      using Support::DeepDup

      attr_reader :source, :proxied_calls, :nested_proxies

      def initialize(source, subscribers)
        @source, @subscribers = source, subscribers
        @proxied_calls = []
        @subscribable = true
        @nested_proxies = []
      end

      IVARS_TO_DUP = %i(@proxied_calls @nested_proxies)
      def deep_dup
        super.tap do |duped|
          IVARS_TO_DUP.each do |ivar|
            duped.instance_variable_set(ivar, duped.instance_variable_get(ivar).deep_dup)
          end
        end
      end

      def method_missing(method_name, *args, &block)
        if @source.command?(method_name)
          dup.tap { |duped_proxy|
            result = @source.command(method_name).call(*args) { |yielded_result|
              duped_proxy.instance_variable_set(:@source, yielded_result)
              yield duped_proxy if block_given?
            }

            @subscribers.did_mutate(
              @source.source_name, args[0], result
            )
          }
        elsif @source.query?(method_name) || @source.modifier?(method_name)
          dup.tap { |duped_proxy|
            nested_calls = []

            new_source = if block_given? && @source.block_for_nested_source?(method_name)
              # In this case a block has been passed that would, without intervention,
              # be called in context of a source instance. We don't want that, since
              # it would provide full access to the underlying dataset. Instead the
              # exposed object should simply be another proxy.

              local_subscribers = @subscribers
              @source.source_from_self.public_send(method_name, *args) {
                nested_proxy = Proxy.new(self, local_subscribers)
                nested_proxy.instance_variable_set(:@proxied_calls, nested_calls)
                nested_proxy.instance_exec(&block).source.tap do |nested_proxy_source|
                  duped_proxy.nested_proxies << nested_proxy.dup.tap do |finalized_nested_proxy|
                    finalized_nested_proxy.instance_variable_set(:@source, nested_proxy_source)
                  end
                end
              }
            else
              @source.source_from_self.public_send(method_name, *args).tap do |working_source|
                working_source.included.each do |_, included_source|
                  nested_proxy = Proxy.new(included_source, @subscribers)
                  duped_proxy.nested_proxies << nested_proxy
                end
              end
            end

            duped_proxy.instance_variable_set(:@source, new_source)
            duped_proxy.instance_variable_get(:@proxied_calls) << [
              method_name, args, nested_calls
            ]
          }
        else
          if Array.instance_methods.include?(method_name) && !@source.class.instance_methods.include?(method_name)
            @proxied_calls << [
              method_name, args, []
            ]

            build_result(@source.to_a.public_send(method_name, *args, &block), method_name)
          elsif @source.class.instance_methods.include?(method_name)
            @proxied_calls << [
              method_name, args, []
            ]

            build_result(@source.public_send(method_name, *args, &block), method_name)
          else
            super
          end
        end
      end

      def respond_to_missing?(method_name, include_private = false)
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
          subscriptions << {
            source: @source.source_name,
            ephemeral: @source.is_a?(Sources::Ephemeral),
            handler: handler,
            payload: payload,
            qualifications: qualifications,
            proxy: to_h
          }

          @nested_proxies.each do |related_proxy|
            subscriptions.concat(
              related_proxy.subscribe_related(
                parent_source: @source,
                serialized_proxy: to_h,
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

        if association = parent_source.class.find_association_to_source(@source)
          parent_source.each do |parent_result|
            subscriptions << {
              source: @source.source_name,
              handler: handler,
              payload: payload,
              qualifications: qualifications.merge(
                association.associated_query_field => parent_result[association.query_field]
              ),
              proxy: serialized_proxy
            }
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

      def to_h
        {
          source: @source.source_name,
          proxied_calls: @proxied_calls
        }
      end

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

      def qualifications
        @proxied_calls.inject(@source.qualifications) { |qualifications, proxied_call|
          qualifications_for_proxied_call = @source.class.qualifications(proxied_call[0]).dup

          # Populate argument qualifications with argument values.
          #
          qualifications_for_proxied_call.each do |qualification_key, qualification_value|
            next unless qualification_value.to_s.start_with?("__arg")
            arg_number = qualification_value.to_s.gsub(/[^0-9]/, "").to_i
            qualifications_for_proxied_call[qualification_key] = @source.class.attributes[qualification_key][proxied_call[1][arg_number]]
          end

          qualifications.merge(qualifications_for_proxied_call)
        }
      end

      private

      def build_result(value, method_name)
        if method_name.to_s.end_with?("?")
          value
        else
          Result.new(value, self)
        end
      end
    end
  end
end
