# frozen_string_literal: true

require "digest/sha1"
require "redis"
require "concurrent/timer_task"

module Pakyow
  module Data
    class Subscribers
      module Adapter
        # Manages data subscriptions in redis.
        #
        # Use this in production.
        #
        # @api private
        class Redis
          class << self
            def stringify_subscription(subscription)
              Marshal.dump(subscription)
            end

            def generate_subscription_id(subscription_string)
              Digest::SHA1.hexdigest(subscription_string)
            end
          end

          KEY_PART_SEPARATOR = "/"
          KEY_PREFIX = "data"
          INFINITY = "+inf"

          def initialize(config)
            @redis = ::Redis.new(url: config[:redis])
            @prefix = [config[:redis_prefix], KEY_PREFIX].join(KEY_PART_SEPARATOR)

            Concurrent::TimerTask.new(execution_interval: 300, timeout_interval: 300) {
              @redis.scan_each(match: key_subscription_ids_by_source("*")) do |key|
                Pakyow.logger.debug "[Pakyow::Data::Subscribers::Adapter::Redis] Cleaning up expired subscriptions for #{key}"
                removed_count = @redis.zremrangebyscore(key, 0, Time.now.to_i)
                Pakyow.logger.debug "[Pakyow::Data::Subscribers::Adapter::Redis] Removed #{removed_count} members for #{key}"
              end
            }.execute
          end

          def register_subscriptions(subscriptions, subscriber: nil)
            [].tap do |subscription_ids|
              @redis.multi do |transaction|
                subscriptions.each do |subscription|
                  subscription_string = self.class.stringify_subscription(subscription)
                  subscription_id = self.class.generate_subscription_id(subscription_string)
                  source = subscription[:source]

                  # store the subscription
                  transaction.set(key_subscription_id(subscription_id), subscription_string)

                  # add the subscription to the subscriber's set
                  transaction.zadd(key_subscription_ids_by_subscriber(subscriber), INFINITY, subscription_id)

                  # add the subscriber to the subscription's set
                  transaction.zadd(key_subscribers_by_subscription_id(subscription_id), INFINITY, subscriber)

                  # add the subscription to the source's set
                  transaction.zadd(key_subscription_ids_by_source(source), INFINITY, subscription_id)

                  # define what source the subscription is for
                  transaction.set(key_source_for_subscription_id(subscription_id), source)

                  subscription_ids << subscription_id
                end
              end
            end
          end

          def subscriptions_for_source(source)
            subscriptions_for_subscription_ids(subscription_ids_for_source(source)).compact
          end

          def unsubscribe(subscriber)
            expire(subscriber, 0)
          end

          def expire(subscriber, seconds)
            time_expire = Time.now.to_i + seconds

            subscription_ids = subscription_ids_for_subscriber(subscriber)

            expire_subscriber_on_these_keys = subscription_ids.map { |subscription_id|
              key_subscribers_by_subscription_id(subscription_id)
            }

            # expire the subscriber
            @redis.multi do |transaction|
              expire_subscriber_on_these_keys.each do |key|
                transaction.zadd(key, time_expire, subscriber)
              end

              transaction.expireat(key_subscription_ids_by_subscriber(subscriber), time_expire + 1)
            end

            # at this point the subscriber has been expired, but we haven't dealt with the subscription
            # if all subscribers have been removed from a subscription, expire the subscription
            subscription_ids.each do |subscription_id|
              key_subscribers_for_subscription_id = key_subscribers_by_subscription_id(subscription_id)

              # this means that if a subscriber is added to the subscription, the following block will not be executed
              @redis.watch(key_subscribers_for_subscription_id) do
                non_expire_count = @redis.zcount(key_subscribers_for_subscription_id, INFINITY, INFINITY)

                if non_expire_count == 0
                  source = @redis.get(key_source_for_subscription_id(subscription_id))

                  last_time_expire = @redis.zrevrangebyscore(
                    key_subscribers_for_subscription_id, INFINITY, 0, with_scores: true, limit: [0, 1]
                  )[0][1].to_i

                  @redis.multi do |transaction|
                    transaction.zadd(key_subscription_ids_by_source(source), last_time_expire, subscription_id)

                    transaction.expireat(key_source_for_subscription_id(subscription_id), last_time_expire + 1)
                    transaction.expireat(key_subscribers_by_subscription_id(subscription_id), last_time_expire + 1)
                    transaction.expireat(key_subscription_id(subscription_id), last_time_expire + 1)
                  end
                end
              end
            end
          end

          def persist(subscriber)
            subscription_ids = subscription_ids_for_subscriber(subscriber)

            persist_subscriber_on_these_keys = subscription_ids.map { |subscription_id|
              key_subscribers_by_subscription_id(subscription_id)
            }

            @redis.multi do |transaction|
              persist_subscriber_on_these_keys.each do |key|
                transaction.zadd(key, INFINITY, subscriber)
              end

              transaction.persist(key_subscription_ids_by_subscriber(subscriber))
            end

            # at this point we've persisted the subscriber, but we haven't dealt with the subscription
            # since the subscriber has been persisted we need to persist each subscription
            subscription_ids.each do |subscription_id|
              key_subscribers_for_subscription_id = key_subscribers_by_subscription_id(subscription_id)

              # this means that if a subscriber is added to the subscription, the following block will not be executed
              @redis.watch(key_subscribers_for_subscription_id) do
                source = @redis.get(key_source_for_subscription_id(subscription_id))

                @redis.multi do |transaction|
                  transaction.zadd(key_subscription_ids_by_source(source), INFINITY, subscription_id)

                  transaction.persist(key_source_for_subscription_id(subscription_id))
                  transaction.persist(key_subscribers_by_subscription_id(subscription_id))
                  transaction.persist(key_subscription_id(subscription_id))
                end
              end
            end
          end

          def expiring?(subscriber)
            @redis.ttl(key_subscription_ids_by_subscriber(subscriber)) > -1
          end

          def subscribers_for_subscription_id(subscription_id)
            @redis.zrangebyscore(
              key_subscribers_by_subscription_id(
                subscription_id
              ), Time.now.to_i, INFINITY
            ).map(&:to_sym)
          end

          protected

          def subscription_ids_for_source(source)
            @redis.zrangebyscore(
              key_subscription_ids_by_source(
                source
              ), Time.now.to_i, INFINITY
            )
          end

          def subscription_ids_for_subscriber(subscriber)
            @redis.zrangebyscore(
              key_subscription_ids_by_subscriber(subscriber), Time.now.to_i, INFINITY
            )
          end

          def subscriptions_for_subscription_ids(subscription_ids)
            return [] if subscription_ids.empty?

            @redis.mget(subscription_ids.map { |subscription_id|
              key_subscription_id(subscription_id)
            }).zip(subscription_ids).map { |subscription_string, subscription_id|
              begin
                Marshal.restore(subscription_string).tap do |subscription|
                  subscription[:id] = subscription_id
                end
              rescue TypeError
                Pakyow.logger.error "could not find subscription for #{subscription_id}"
                {}
              end
            }
          end

          def build_key(*parts)
            [@prefix].concat(parts).join(KEY_PART_SEPARATOR)
          end

          def key_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}")
          end

          def key_subscribers_by_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}", "subscribers")
          end

          def key_subscription_ids_by_subscriber(subscriber)
            build_key("subscriber:#{subscriber}")
          end

          def key_subscription_ids_by_source(source)
            build_key("source:#{source}")
          end

          def key_source_for_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}", "source")
          end
        end
      end
    end
  end
end
