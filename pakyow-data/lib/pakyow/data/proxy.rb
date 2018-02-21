# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"

module Pakyow
  module Data
    class Proxy
      class << self
        def deserialize(info, model_proxy)
          info[:proxied_calls].each do |proxied_call|
            model_proxy = model_proxy.public_send(proxied_call[:call], *proxied_call[:args])
          end

          model_proxy
        end
      end

      using Support::Refinements::Array::Ensurable

      attr_reader :model, :proxied_calls

      def initialize(model, subscribers)
        @model, @subscribers = model, subscribers
        @proxied_calls = []
        @subscribable = true
      end

      def method_missing(method_name, *args, &block)
        result = @model.public_send(method_name, *args, &block)

        if @model.command?(method_name)
          @subscribers.did_mutate(@model.class.__class_name.name, args[0], Array.ensure(result))
          return result
        end

        if result.class.name.include?("ROM::Relation")
          proxy = dup
          proxy.instance_variable_set(:@model, @model.class.new(result))
          proxy.instance_variable_get(:@proxied_calls) << {
            call: method_name,
            args: args
          }

          return proxy
        else
          return result
        end
      end

      def respond_to_missing?(*)
        # All method calls are forwarded to the model.
        #
        true
      end

      def subscribe(subscriber, handler: nil, payload: nil)
        subscription_ids = []

        if subscribable?
          subscription = {
            model: @model.class.__class_name.name,
            handler: handler,
            payload: payload,
            qualifications: @proxied_calls.inject({}) { |qualifications, proxied_call|
              qualifications.merge(@model.class.qualifications(proxied_call[:call]))
            },
            subscriber: subscriber,
            proxy: to_h
          }

          subscription_ids << @subscribers.register_subscription(subscription, subscriber: subscriber)

          # Register subscriptions for any combined models.
          #
          if @model.__getobj__.is_a?(ROM::Relation::Combined)
            primary_key = @model.class._primary_key
            @model.root.select(primary_key).to_a.each do |result|
              nodes.each do |node|
                combined_subscription = {
                  model: node.name.to_sym,
                  handler: handler,
                  payload: payload,
                  qualifications: {
                    :"#{Support.inflector.singularize(@model.class.__class_name.name)}_#{primary_key}" => result[primary_key]
                  },
                  proxy: to_h
                }

                subscription_ids << @subscribers.register_subscription(combined_subscription, subscriber: subscriber)
              end
            end
          end
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
          model: @model.class.__class_name.name,
          proxied_calls: @proxied_calls
        }
      end
    end
  end
end
