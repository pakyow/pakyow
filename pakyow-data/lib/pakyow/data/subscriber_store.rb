# frozen_string_literal: true

require "pakyow/support/core_refinements/method/introspection"

module Pakyow
  module Data
    # @api private
    class SubscriberStore
      attr_accessor :lookup

      using Support::Method::Introspection

      # TODO: pass in the adapter and config
      def initialize(app_name, adapter = :memory, adapter_config = {})
        require "pakyow/data/subscriber_store/adapters/#{adapter}"
        @adapter = Pakyow::Data::SubscriberStore::Adapter.const_get(adapter.to_s.capitalize).new(app_name, adapter_config)
      rescue LoadError => e
        Pakyow.logger.error "Failed to load data subscriber store adapter named `#{adapter}'"
        Pakyow.logger.error e.message
      end

      def register_subscription(subscription, subscriber: nil, object_ids: [])
        @adapter.persist(subscriber) if @adapter.expiring?(subscriber)
        @adapter.register_subscription(subscription, subscriber: subscriber, object_ids: object_ids)
      end

      def did_mutate(model, changed_values, changed_ids)
        subscriptions = Set.new

        changed_ids.each do |id|
          @adapter.subscriptions_for_model_object(model, id).each do |subscription|
            subscription.delete(:qualifications)
            subscriptions << subscription
          end
        end

        @adapter.subscriptions_for_model(model).each do |subscription|
          next unless qualified?(subscription.delete(:qualifications), changed_values)
          subscriptions << subscription
        end

        subscriptions.each do |subscription|
          process(subscription)
        end
      end

      def unsubscribe(subscriber)
        @adapter.unsubscribe(subscriber)
      end

      def expire(subscriber, seconds)
        @adapter.expire(subscriber, seconds)
      end

      def persist(subscriber)
        @adapter.persist(subscriber)
      end

      protected

      def process(subscription)
        model_object = lookup.send(subscription[:model])
        callback = subscription[:handler].new
        query = model_object.send(subscription[:query], *subscription[:query_args])
        arguments = {}

        if subscription.key?(:query) && callback.method(:call).keyword_argument?(:query)
          arguments[:query] = query
        end

        if callback.method(:call).keyword_argument?(:subscribers)
          arguments[:subscribers] = @adapter.subscribers_for_subscription_id(subscription[:id])
        end

        callback.call(subscription[:payload], **arguments)

        # since the resulting ids from the query may have changed, update them
        @adapter.update_model_object_ids_for_subscription_id(subscription[:model], query.object_ids, subscription[:id])
      end

      def qualified?(qualifications, changed_values)
        qualifications.each do |key, value|
          return false unless (value == :* && changed_values.key?(key)) || changed_values[key] == value
        end

        true
      end
    end
  end
end
