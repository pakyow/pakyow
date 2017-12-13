# frozen_string_literal: true

require "pakyow/support/core_refinements/method/introspection"

module Pakyow
  module Data
    # @api private
    class Subscribers
      attr_accessor :lookup

      using Support::Method::Introspection

      def initialize(app, adapter = :memory, adapter_config = {})
        @app = app
        require "pakyow/data/subscribers/adapters/#{adapter}"
        @adapter = Pakyow::Data::Subscribers::Adapter.const_get(adapter.to_s.capitalize).new(adapter_config)
      rescue LoadError => e
        Pakyow.logger.error "Failed to load data subscriber store adapter named `#{adapter}'"
        Pakyow.logger.error e.message
      end

      def register_subscription(subscription, subscriber: nil)
        @adapter.persist(subscriber) if @adapter.expiring?(subscriber)
        @adapter.register_subscription(subscription, subscriber: subscriber)
      end

      def did_mutate(model, changed_values, changed_results)
        subscriptions = Set.new

        @adapter.subscriptions_for_model(model).each do |subscription|
          next unless qualified?(subscription.delete(:qualifications), changed_values, changed_results)
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
        callback = subscription[:handler].new(@app)
        arguments = {}

        if subscription.key?(:query) && callback.method(:call).keyword_argument?(:query)
          arguments[:query] = lookup.send(subscription[:model]).send(subscription[:query], *subscription[:query_args])
        end

        if callback.method(:call).keyword_argument?(:subscribers)
          arguments[:subscribers] = @adapter.subscribers_for_subscription_id(subscription[:id])
        end

        if callback.method(:call).keyword_argument?(:id)
          arguments[:id] = subscription[:id]
        end

        callback.call(subscription[:payload], **arguments)
      end

      def qualified?(qualifications, changed_values, changed_results)
        qualifications.each do |key, value|
          return false unless changed_values[key] == value || qualified_result?(key, value, changed_results)
        end

        true
      end

      def qualified_result?(key, value, changed_results)
        changed_results.each do |result|
          return true if result[key] == value
        end

        false
      end
    end
  end
end
