# frozen_string_literal: true

require "concurrent/executor/thread_pool_executor"

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
        @executor = Concurrent::ThreadPoolExecutor.new(
          min_threads: 1,
          max_threads: 10,
          max_queue: 0
        )
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
      def register_subscriptions(subscriptions, subscriber: nil)
        @adapter.persist(subscriber) if @adapter.expiring?(subscriber)
        @adapter.register_subscriptions(subscriptions, subscriber: subscriber)
      end

      def did_mutate(source_name, changed_values, result_source)
        @executor << Proc.new {
          begin
            @adapter.subscriptions_for_source(source_name).select { |subscription|
              subscription[:handler] && qualified?(
                subscription.delete(:qualifications).to_a,
                changed_values,
                result_source.to_a,
                result_source.original_results || []
              )
            }.uniq.each do |subscription|
              process(subscription)
            end
          rescue => error
            Pakyow.logger.error "[Pakyow::Data::Subscribers] did_mutate failed: #{error}"
          end
        }
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

      QUALIFIABLE_TYPES = [Hash, Support::IndifferentHash]
      def qualified?(qualifications, changed_values, changed_results, original_results)
        qualifications.all? do |key, value|
          (QUALIFIABLE_TYPES.include?(changed_values.class) && changed_values.to_h[key] == value) || qualified_result?(key, value, changed_results, original_results)
        end
      end

      def qualified_result?(key, value, changed_results, original_results)
        original_results.concat(changed_results).any? do |result|
          result[key] == value
        end
      end
    end
  end
end
