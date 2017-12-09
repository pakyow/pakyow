# frozen_string_literal: true

require "digest/sha1"
require "redis"

require "pakyow/data/subscriber_store/adapters/redis/pipeliner"

module Pakyow
  module Data
    class SubscriberStore
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

          def initialize(app_name, config)
            @redis = ::Redis.new(url: config[:redis])

            @prefix = [
              config[:redis_prefix],
              app_name,
              KEY_PREFIX
            ].join(KEY_PART_SEPARATOR)
          end

          def register_subscription(subscription, subscriber: nil, object_ids: [])
            subscription_string = self.class.stringify_subscription(subscription)
            subscription_id = self.class.generate_subscription_id(subscription_string)

            model = subscription[:model]

            @redis.multi do |transaction|
              # store the subscription
              transaction.set(key_subscription_id(subscription_id), subscription_string)

              # add the subscription to the subscriber's set
              transaction.zadd(key_subscription_ids_by_subscriber(subscriber), INFINITY, subscription_id)

              # add the subscriber to the subscription's set
              transaction.zadd(key_subscribers_by_subscription_id(subscription_id), INFINITY, subscriber)

              # add the subscription to the model's set
              transaction.zadd(key_subscription_ids_by_model(model), INFINITY, subscription_id)

              # define what model the subscription is for
              transaction.set(key_model_for_subscription_id(subscription_id), model)

              # add the subscription to each model object
              register_model_object_ids_for_subscription_id(object_ids, model, subscription_id, transaction)
            end

            subscription_id
          end

          def update_model_object_ids_for_subscription_id(model, object_ids, subscription_id)
            @redis.multi do |transaction|
              register_model_object_ids_for_subscription_id(object_ids, model, subscription_id, transaction)
            end
          end

          def subscriptions_for_model(model)
            subscriptions_for_subscription_ids(subscription_ids_for_model(model))
          end

          def subscriptions_for_model_object(model, object_id)
            subscriptions_for_subscription_ids(subscription_ids_for_model_object(model, object_id))
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
              transaction.expireat(key_subscription_ids_by_subscriber(subscriber), time_expire + 1)

              expire_subscriber_on_these_keys.each do |key|
                transaction.zadd(key, time_expire, subscriber)
              end
            end

            # at this point the subscriber has been expired, but we haven't dealt with the subscription
            # if all subscribers have been removed from a subscription, expire the subscription
            subscription_ids.each do |subscription_id|
              key_subscribers_for_subscription_id = key_subscribers_by_subscription_id(subscription_id)

              # this means that if a subscriber is added to the subscription, the following block will not be executed
              @redis.watch(key_subscribers_for_subscription_id) do
                non_expire_count = @redis.zcount(key_subscribers_for_subscription_id, INFINITY, INFINITY)

                if non_expire_count == 0
                  model = @redis.get(key_model_for_subscription_id(subscription_id))
                  objects = @redis.smembers(key_objects_for_subscription_id(subscription_id))

                  last_time_expire = @redis.zrevrangebyscore(
                    key_subscribers_for_subscription_id, INFINITY, 0, with_scores: true, limit: [0, 1]
                  )[0][1].to_i

                  @redis.multi do |transaction|
                    transaction.zadd(key_subscription_ids_by_model(model), last_time_expire, subscription_id)

                    objects.each do |object|
                      transaction.zadd(
                        key_subscription_ids_by_model_object_id(
                          model,
                          object
                        ),

                        last_time_expire, subscription_id
                      )
                    end

                    transaction.expireat(key_model_for_subscription_id(subscription_id), last_time_expire + 1)
                    transaction.expireat(key_objects_for_subscription_id(subscription_id), last_time_expire + 1)
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
              transaction.persist(key_subscription_ids_by_subscriber(subscriber))

              persist_subscriber_on_these_keys.each do |key|
                transaction.zadd(key, INFINITY, subscriber)
              end
            end

            # at this point we've expired the subscribers, but we haven't dealt with the subscription
            # so now, if all subscribers have been removed we need to expire each subscription
            subscription_ids.each do |subscription_id|
              key_subscribers_for_subscription_id = key_subscribers_by_subscription_id(subscription_id)

              # this means that if a subscriber is added to the subscription, the following block will not be executed
              @redis.watch(key_subscribers_for_subscription_id) do
                model = @redis.get(key_model_for_subscription_id(subscription_id))
                objects = @redis.smembers(key_objects_for_subscription_id(subscription_id))

                @redis.multi do |transaction|
                  transaction.zadd(key_subscription_ids_by_model(model), INFINITY, subscription_id)

                  objects.each do |object|
                    transaction.zadd(
                      key_subscription_ids_by_model_object_id(
                        model,
                        object
                      ),

                      INFINITY, subscription_id
                    )
                  end

                  transaction.persist(key_model_for_subscription_id(subscription_id))
                  transaction.persist(key_objects_for_subscription_id(subscription_id))
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

          def register_model_object_ids_for_subscription_id(object_ids, model, subscription_id, transaction = @redis)
            object_ids.each do |object_id|
              # add the subscription to each model object's set
              transaction.zadd(key_subscription_ids_by_model_object_id(model, object_id), INFINITY, subscription_id)

              # add the object to the subscription's set
              transaction.sadd(key_objects_for_subscription_id(subscription_id), object_id)
            end
          end

          def subscription_ids_for_model(model)
            @redis.zrangebyscore(
              key_subscription_ids_by_model(
                model
              ), Time.now.to_i, INFINITY
            )
          end

          def subscription_ids_for_model_object(model, object_id)
            @redis.zrangebyscore(
              key_subscription_ids_by_model_object_id(
                model, object_id
              ), Time.now.to_i, INFINITY
            )
          end

          def subscription_ids_for_subscriber(subscriber)
            @redis.zrangebyscore(
              key_subscription_ids_by_subscriber(subscriber), Time.now.to_i, INFINITY
            )
          end

          def subscriptions_for_subscription_ids(subscription_ids)
            Pipeliner.pipeline @redis do |pipeline|
              subscription_ids.each do |subscription_id|
                pipeline.enqueue(@redis.get(key_subscription_id(subscription_id))) do |subscription_string|
                  subscription = Marshal.restore(subscription_string)
                  subscription[:id] = subscription_id
                  subscription
                end
              end
            end
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

          def key_subscription_ids_by_model(model)
            build_key("model:#{model}")
          end

          def key_subscription_ids_by_model_object_id(model, object_id)
            build_key("model:#{model}", "object:#{object_id}")
          end

          def key_model_for_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}", "model")
          end

          def key_objects_for_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}", "objects")
          end
        end
      end
    end
  end
end
