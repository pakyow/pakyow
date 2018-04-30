# frozen_string_literal: true

require "pakyow/support/core_refinements/method/introspection"

module Pakyow
  module Data
    # @api private
    class Subscribers
      attr_accessor :lookup

      using Support::Refinements::Method::Introspection

      def initialize(app, adapter = :memory, adapter_config = {})
        @app = app
        require "pakyow/data/subscribers/adapters/#{adapter}"
        @adapter = Pakyow::Data::Subscribers::Adapter.const_get(adapter.to_s.capitalize).new(adapter_config)
      rescue LoadError => e
        Pakyow.logger.error "Failed to load data subscriber store adapter named `#{adapter}'"
        Pakyow.logger.error e.message
      end

      # {
      #   source
      #   qualifications
      #   object_pks
      #   pk_field
      #   handler
      #   proxy => source
      #   payload
      # }
      def register_subscription(subscription, subscriber: nil)
        @adapter.persist(subscriber) if @adapter.expiring?(subscriber)
        @adapter.register_subscription(subscription, subscriber: subscriber)
      end

      def did_mutate(source_name, changed_values, changed_results)
        subscriptions = Set.new

        @adapter.subscriptions_for_source(source_name).each do |subscription|
          if qualified?(subscription.delete(:qualifications), subscription.delete(:object_pks), subscription.delete(:pk_field), changed_values, changed_results)
            subscriptions << subscription
          end
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

        if callback.method(:call).keyword_argument?(:result)
          arguments[:result] = @app.data.public_send(
            subscription[:proxy][:source]
          ).apply(subscription[:proxy][:proxied_calls])
        end

        if callback.method(:call).keyword_argument?(:subscribers)
          arguments[:subscribers] = @adapter.subscribers_for_subscription_id(subscription[:id])
        end

        if callback.method(:call).keyword_argument?(:id)
          arguments[:id] = subscription[:id]
        end

        if callback.method(:call).keyword_argument?(:subscription)
          arguments[:subscription] = subscription
        end

        callback.call(subscription[:payload], **arguments)
      end

      def qualified?(qualifications, object_pks, pk_field, changed_values, changed_results)
        changed_results.each do |changed_result|
          return true if object_pks.include?(changed_result[pk_field])
        end

        qualifications.each do |key, value|
          return false unless changed_values.to_h[key] == value || qualified_result?(key, value, changed_results)
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
