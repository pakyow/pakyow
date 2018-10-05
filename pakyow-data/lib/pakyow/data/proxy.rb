# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/inspectable"

module Pakyow
  module Data
    # @api private
    class Proxy
      include Support::Inspectable
      inspectable :source

      using Support::Refinements::Array::Ensurable

      attr_reader :source, :proxied_calls, :nested_proxies

      def initialize(source, subscribers)
        @source, @subscribers = source, subscribers
        @proxied_calls = []
        @subscribable = true
        @nested_proxies = []
      end

      def method_missing(method_name, *args, &block)
        if @source.command?(method_name)
          dup.tap { |proxy|
            result = @source.command(method_name).call(*args, &block)

            @subscribers.did_mutate(
              @source.source_name, args[0], result
            )

            proxy.instance_variable_set(:@source, result)
          }
        elsif @source.query?(method_name) || @source.modifier?(method_name)
          dup.tap { |proxy|
            nested_calls = []

            source = if block_given? && @source.block_for_nested_source?(method_name)
              # In this case a block has been passed that would, without intervention,
              # be called in context of a source instance. We don't want that, since
              # it would provide full access to the underlying dataset. Instead the
              # exposed object should simply be another proxy.

              local_subscribers = @subscribers
              @source.public_send(method_name, *args) {
                nested_proxy = Proxy.new(self, local_subscribers)
                nested_proxy.instance_variable_set(:@proxied_calls, nested_calls)
                nested_proxy.instance_exec(&block).source.tap do |nested_proxy_source|
                  proxy.nested_proxies << nested_proxy.dup.tap do |finalized_nested_proxy|
                    finalized_nested_proxy.instance_variable_set(:@source, nested_proxy_source)
                  end
                end
              }
            else
              @source.public_send(method_name, *args).tap do |working_source|
                working_source.included.each do |included_source|
                  nested_proxy = Proxy.new(included_source, @subscribers)
                  proxy.nested_proxies << nested_proxy
                end
              end
            end

            proxy.instance_variable_set(:@source, source)
            proxy.instance_variable_get(:@proxied_calls) << [
              method_name, args, nested_calls
            ]
          }
        elsif @source.result?(method_name)
          @source.public_send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, *)
        @source.command?(method_name) || @source.query?(method_name) ||
          @source.result?(method_name) || @source.modifier?(method_name)
      end

      def to_ary
        to_a
      end

      def to_json(*)
        @source.to_json
      end

      def subscribe(subscriber, handler:, payload: nil)
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

        @subscribers.register_subscriptions(subscriptions, subscriber: subscriber)
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
                association[:associated_column_name] => parent_result[association[:column_name]]
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
    end
  end
end
