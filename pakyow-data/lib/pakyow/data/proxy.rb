# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/inspectable"

module Pakyow
  module Data
    class Proxy
      include Support::Inspectable
      inspectable :source

      using Support::Refinements::Array::Ensurable

      attr_reader :source, :proxied_calls

      def initialize(source, subscribers)
        @source, @subscribers = source, subscribers
        @proxied_calls = []
        @subscribable = true
      end

      def method_missing(method_name, *args, &block)
        if @source.command?(method_name)
          @source.command(method_name).call(*args, &block).tap { |result|
            @subscribers.did_mutate(
              @source.class.__class_name.name,
              args[0],
              # TODO: see if compact is still needed
              result.to_a.compact
            )
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
                nested_proxy.instance_exec(&block).source
              }
            else
              @source.public_send(method_name, *args, &block)
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

      def subscribe(subscriber, handler:, payload: nil)
        subscription_ids = []

        if subscribable?
          qualifications = @proxied_calls.inject({}) { |qualifications, proxied_call|
            qualifications_for_proxied_call = @source.class.qualifications(proxied_call[0])

            # Populate argument qualifications with argument values.
            #
            qualifications_for_proxied_call.each do |qualification_key, qualification_value|
              next unless qualification_value.to_s.start_with?("__arg")
              arg_number = qualification_value.to_s.gsub(/[^0-9]/, "").to_i
              qualifications_for_proxied_call[qualification_key] = proxied_call[1][arg_number]
            end

            qualifications.merge(qualifications_for_proxied_call)
          }

          primary_key = @source.class.primary_key_field

          result_pks = @source.map { |object|
            object[primary_key]
          }

          subscription = {
            source: @source.class.__class_name.name,
            handler: handler,
            payload: payload,
            qualifications: qualifications,
            subscriber: subscriber,
            pk_field: primary_key,
            object_pks: result_pks,
            proxy: to_h
          }

          subscription_ids << @subscribers.register_subscription(subscription, subscriber: subscriber)

          @source.included.each do |included_source|
            subscription_ids.concat(
              subscribe_included_source(
                included_source,
                subscriber: subscriber,
                handler: handler,
                payload: payload
              )
            )
          end
        end

        subscription_ids
      end

      def subscribe_included_source(source, subscriber:, handler:, payload:)
        subscription_ids = []

        primary_key = source.class.primary_key_field

        result_pks = source.map { |object|
          object[primary_key]
        }

        subscription = {
          source: source.class.__class_name.name,
          handler: handler,
          payload: payload,
          # qualifications: {
          #   :"#{Support.inflector.singularize(@source.model.__class_name.name)}_#{primary_key}" => result_pk_value
          # },
          subscriber: subscriber,
          qualifications: {},
          pk_field: primary_key,
          object_pks: result_pks,
          proxy: to_h
        }

        subscription_ids << @subscribers.register_subscription(subscription, subscriber: subscriber)

        source.included.each do |included_source|
          subscription_ids.concat(
            subscribe_included_source(
              included_source,
              subscriber: subscriber,
              handler: handler,
              payload: payload
            )
          )
        end

        subscription_ids
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
          source: @source.class.__class_name.name,
          proxied_calls: @proxied_calls
        }
      end

      # @api private
      def apply(proxied_calls)
        proxied_calls.inject(self) { |_proxy, proxied_call|
          if proxied_call[2].any?
            public_send(proxied_call[0], *proxied_call[1]) do
              apply(proxied_call[2])
            end
          else
            public_send(proxied_call[0], *proxied_call[1])
          end
        }
      end
    end
  end
end
