# frozen_string_literal: true

require "concurrent/executor/thread_pool_executor"

require "pakyow/support/core_refinements/method/introspection"
require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    # @api private
    class Subscribers
      attr_accessor :lookup, :adapter

      extend Support::DeepFreeze
      insulate :executor

      using Support::Refinements::Method::Introspection

      def initialize(app, adapter = :memory, adapter_config = {})
        @app = app

        require_relative "subscribers/adapters/#{adapter}"
        @adapter = Pakyow::Data::Subscribers::Adapters.const_get(
          adapter.to_s.capitalize
        ).new(
          adapter_config.to_h.merge(
            app.config.data.subscriptions.adapter_settings.to_h
          )
        )

        @executor = Concurrent::ThreadPoolExecutor.new(
          auto_terminate: false,
          min_threads: 1,
          max_threads: 10,
          max_queue: 0
        )
      rescue LoadError, NameError => error
        raise UnknownSubscriberAdapter.build(error, adapter: adapter)
      end

      def shutdown
        @executor.shutdown
        @executor.wait_for_termination(30)
      end

      def register_subscriptions(subscriptions, subscriber: nil, &block)
        subscriptions.each do |subscription|
          subscription[:version] = @app.config.data.subscriptions.version
        end

        ids = @adapter.register_subscriptions(subscriptions, subscriber: subscriber)
        yield ids if block_given?
        ids
      end

      def did_mutate(given_source_name, given_changed_values = nil, given_result_source = nil)
        @executor.post(given_source_name, given_changed_values, given_result_source, Pakyow.logger.target) do |source_name, changed_values, result_source, logger|
          logger.internal do
            "[Pakyow::Data::Subscribers] did mutate #{source_name}"
          end

          subscriptions = @adapter.subscriptions_for_source(source_name)

          logger.internal do
            "[Pakyow::Data::Subscribers] fetched #{subscriptions.count} subscriptions"
          end

          subscriptions.uniq { |subscription|
            subscription.dig(:payload, :id) || subscription
          }.select { |subscription|
            process?(subscription, changed_values, result_source)
          }.each do |subscription|
            if subscription[:version] == @app.config.data.subscriptions.version
              begin
                logger.internal do
                  "[Pakyow::Data::Subscribers] processing subscription #{subscription[:id]}"
                end

                process(subscription, result_source)

                logger.internal {
                  "[Pakyow::Data::Subscribers] finished processing subscription #{subscription[:id]}"
                }
              rescue => error
                logger.error {
                  "[Pakyow::Data::Subscribers] did_mutate failed: #{error}"
                }
              end
            end
          end

          logger.internal {
            "[Pakyow::Data::Subscribers] finished mutate for #{source_name}"
          }
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

      private

      def process?(subscription, changed_values, result_source)
        subscription[:handler] && qualified_subscription?(subscription, changed_values, result_source)
      end

      def process(subscription, mutated_source)
        callback = subscription[:handler].new(@app)
        arguments = {}

        if callback.method(:call).keyword_argument?(:id)
          arguments[:id] = subscription[:id]
        end

        if callback.method(:call).keyword_argument?(:result)
          arguments[:result] = if subscription[:ephemeral]
            mutated_source
          else
            subscription[:proxy]
          end
        end

        if callback.method(:call).keyword_argument?(:subscription)
          arguments[:subscription] = subscription
        end

        callback.call(subscription[:payload], **arguments)
      end

      def qualified_subscription?(subscription, changed_values, result_source)
        if subscription[:ephemeral]
          result_source.qualifications == subscription[:qualifications]
        else
          original_results = if result_source
            result_source.original_results
          else
            []
          end

          qualified?(
            subscription.delete(:qualifications).to_a,
            changed_values,
            result_source.to_a,
            original_results.to_a
          )
        end
      end

      QUALIFIABLE_TYPES = [Hash, Support::IndifferentHash].freeze
      def qualified?(qualifications, changed_values, changed_results, original_results)
        qualifications.all? do |key, value|
          (
            QUALIFIABLE_TYPES.include?(changed_values.class) && (
              (
                value.is_a?(Array) && value.include?(changed_values.to_h[key])
              ) || changed_values.to_h[key] == value
            )
          ) || qualified_result?(key, value, changed_results, original_results)
        end
      end

      def qualified_result?(key, value, changed_results, original_results)
        original_results.concat(changed_results).any? do |result|
          (value.is_a?(Array) && value.include?(result[key])) || result[key] == value
        end
      end
    end
  end
end
