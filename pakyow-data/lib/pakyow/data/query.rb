# frozen_string_literal: true

module Pakyow
  module Data
    # Wraps a dataset to keep track of what query it originated from.
    #
    class Query < SimpleDelegator
      attr_reader :name, :args, :model

      def initialize(model, name, args, subscribers)
        @model, @name, @args, @subscribers = model, name, args, subscribers
        @subscribable = true
        __setobj__(model)
      end

      # TODO: support passing a mapper through an `as` method that uses map_to behind the scenes

      def subscribe(subscriber, call: nil, with: nil)
        return unless subscribable?

        model = @model.name

        subscription = {
          model: model,
          query: @name,
          query_args: @args,
          handler: call,
          payload: with,
          qualifications: qualifications
        }

        @subscribers.register_subscription(subscription, subscriber: subscriber)
      end

      def subscribable(boolean)
        tap do
          @subscribable = boolean
        end
      end

      def subscribable?
        @subscribable == true
      end

      def qualifications
        @model.qualifications(@name)
      end
    end
  end
end
