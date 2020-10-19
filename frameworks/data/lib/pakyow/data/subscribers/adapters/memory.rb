# frozen_string_literal: true

require "digest/sha1"

require "concurrent/array"
require "concurrent/hash"
require "concurrent/timer_task"

require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Subscribers
      module Adapters
        # Manages data subscriptions in memory.
        #
        # Great for development, not for use in production!
        #
        # @api private
        class Memory
          class << self
            def generate_subscription_id(subscription)
              Digest::SHA1.hexdigest(Marshal.dump(subscription))
            end
          end

          using Support::DeepDup

          include Support::DeepFreeze
          insulate :subscriptions_by_id, :subscription_ids_by_source, :subscribers_by_subscription_id, :subscription_ids_by_subscriber, :expirations_for_subscriber

          def initialize(*)
            @subscriptions_by_id = Concurrent::Hash.new
            @subscription_ids_by_source = Concurrent::Hash.new
            @subscribers_by_subscription_id = Concurrent::Hash.new
            @subscription_ids_by_subscriber = Concurrent::Hash.new
            @expirations_for_subscriber = Concurrent::Hash.new

            Concurrent::TimerTask.new(execution_interval: 10, timeout_interval: 10) {
              @expirations_for_subscriber.each do |subscriber, timeout|
                if timeout < Time.now
                  unsubscribe(subscriber)
                end
              end
            }.execute
          end

          def register_subscriptions(subscriptions, subscriber: nil)
            subscriptions.map { |subscription|
              subscription_id = self.class.generate_subscription_id(subscription)
              register_subscription_with_subscription_id(subscription, subscription_id)
              register_subscription_id_for_source(subscription_id, subscription[:source])
              register_subscriber_for_subscription_id(subscriber, subscription_id)
              subscription_id
            }
          end

          def subscriptions_for_source(source)
            subscription_ids_for_source(source).map { |subscription_id|
              subscription_with_id(subscription_id)
            }
          end

          def unsubscribe(subscriber)
            subscription_ids_for_subscriber(subscriber).dup.each do |subscription_id|
              unsubscribe_subscriber_from_subscription_id(subscriber, subscription_id)
            end
          end

          def expire(subscriber, seconds)
            @expirations_for_subscriber[subscriber] = Time.now + seconds
          end

          def persist(subscriber)
            @expirations_for_subscriber.delete(subscriber)
          end

          def expiring?(subscriber)
            @expirations_for_subscriber.key?(subscriber)
          end

          def subscribers_for_subscription_id(subscription_id)
            @subscribers_by_subscription_id[subscription_id] || []
          end

          SERIALIZABLE_IVARS = %i[
            @subscriptions_by_id
            @subscription_ids_by_source
            @subscribers_by_subscription_id
            @expirations_for_subscriber
          ].freeze

          def serialize
            SERIALIZABLE_IVARS.each_with_object({}) do |ivar, hash|
              hash[ivar] = instance_variable_get(ivar)
            end
          end

          protected

          def subscription_ids_for_source(source)
            (@subscription_ids_by_source[source] || []).select { |subscription_id|
              subscribers_for_subscription_id(subscription_id).any? { |subscriber|
                !expiring?(subscriber)
              }
            }
          end

          def subscription_with_id(subscription_id)
            subscription = @subscriptions_by_id[subscription_id].deep_dup
            subscription[:id] = subscription_id
            subscription
          end

          def subscription_ids_for_subscriber(subscriber)
            @subscription_ids_by_subscriber[subscriber] || []
          end

          def register_subscription_with_subscription_id(subscription, subscription_id)
            @subscriptions_by_id[subscription_id] = subscription
          end

          def register_subscription_id_for_source(subscription_id, source)
            @subscription_ids_by_source[source] ||= Concurrent::Array.new
            (@subscription_ids_by_source[source] << subscription_id).uniq!
          end

          def register_subscriber_for_subscription_id(subscriber, subscription_id)
            @subscribers_by_subscription_id[subscription_id] ||= Concurrent::Array.new
            (@subscribers_by_subscription_id[subscription_id] << subscriber).uniq!

            @subscription_ids_by_subscriber[subscriber] ||= Concurrent::Array.new
            (@subscription_ids_by_subscriber[subscriber] << subscription_id).uniq!
          end

          def unsubscribe_subscriber_from_subscription_id(subscriber, subscription_id)
            subscribers_for_subscription_id(subscription_id).delete(subscriber)
            subscription_ids_for_subscriber(subscriber).delete(subscription_id)

            if subscribers_for_subscription_id(subscription_id).empty?
              @subscriptions_by_id.delete(subscription_id)

              @subscription_ids_by_source.each do |_, ids|
                ids.delete(subscription_id)
              end
            end
          end
        end
      end
    end
  end
end
