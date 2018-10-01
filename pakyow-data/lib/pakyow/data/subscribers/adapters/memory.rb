# frozen_string_literal: true

require "digest/sha1"

require "concurrent/array"
require "concurrent/hash"
require "concurrent/scheduled_task"

module Pakyow
  module Data
    class Subscribers
      module Adapter
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

          def initialize(_config)
            @subscriptions_by_id = Concurrent::Hash.new
            @subscription_ids_by_source = Concurrent::Hash.new
            @subscribers_by_subscription_id = Concurrent::Hash.new
            @subscription_ids_by_subscriber = Concurrent::Hash.new
            @expirations_for_subscriber = Concurrent::Hash.new
          end

          def register_subscriptions(subscriptions, subscriber: nil)
            subscriptions.map { |subscription|
              self.class.generate_subscription_id(subscription).tap do |subscription_id|
                register_subscription_with_subscription_id(subscription, subscription_id)
                register_subscription_id_for_source(subscription_id, subscription[:source])
                register_subscriber_for_subscription_id(subscriber, subscription_id)
              end
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
            task = Concurrent::ScheduledTask.execute(seconds) {
              unsubscribe(subscriber)
            }

            @expirations_for_subscriber[subscriber] ||= []
            @expirations_for_subscriber[subscriber] << task
          end

          def persist(subscriber)
            (@expirations_for_subscriber[subscriber] || []).each(&:cancel)
            @expirations_for_subscriber.delete(subscriber)
          end

          def expiring?(subscriber)
            @expirations_for_subscriber[subscriber]&.any?
          end

          def subscribers_for_subscription_id(subscription_id)
            @subscribers_by_subscription_id[subscription_id] || []
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
            subscription = @subscriptions_by_id[subscription_id].dup
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
