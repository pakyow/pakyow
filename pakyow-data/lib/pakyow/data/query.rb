# frozen_string_literal: true

module Pakyow
  module Data
    # Wraps a dataset to keep track of what query it originated from.
    #
    class Query < SimpleDelegator
      attr_reader :name, :args, :model

      def initialize(model, name, args, subscriber_store)
        @model, @name, @args, @subscriber_store = model, name, args, subscriber_store

        __setobj__(model)
      end

      # TODO: support passing a mapper through an `as` method that uses map_to behind the scenes

      def subscribe(subscriber, call: nil, with: nil)
        model = @model.name

        subscription = {
          model: model,
          query: @name,
          query_args: @args,
          handler: call,
          payload: with,
          qualifications: qualifications
        }

        @subscriber_store.register_subscription(subscription, subscriber: subscriber, object_ids: object_ids)
      end

      def qualifications
        @model.qualifications(@name)
      end

      def object_ids
        map { |result| result[:id] }
      end
    end
  end
end