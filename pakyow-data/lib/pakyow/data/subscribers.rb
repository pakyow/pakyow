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
          if qualified?(subscription.delete(:qualifications), changed_values, changed_results)
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

        result = if @app.data.respond_to?(subscription[:proxy][:source])
          @app.data.public_send(subscription[:proxy][:source])
        else
          @app.data.ephemeral(subscription[:proxy][:source])
        end

        if callback.method(:call).keyword_argument?(:id)
          arguments[:id] = subscription[:id]
        end

        if callback.method(:call).keyword_argument?(:result)
          arguments[:result] = result.apply(subscription[:proxy][:proxied_calls])
        end

        if callback.method(:call).keyword_argument?(:subscription)
          arguments[:subscription] = subscription
        end

        callback.call(subscription[:payload], **arguments)
      end

      def qualified?(qualifications, changed_values, changed_results)
        qualifications.all? do |key, value|
          changed_values.to_h[key] == value || qualified_result?(key, value, changed_results)
        end
      end

      def qualified_result?(key, value, changed_results)
        changed_results.any? do |result|
          result[key] == value
        end
      end
    end
  end
end
