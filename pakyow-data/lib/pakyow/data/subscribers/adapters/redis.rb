# frozen_string_literal: true

require "digest/sha1"
require "zlib"

require "redis"
require "concurrent/timer_task"
require "connection_pool"

require "pakyow/support/deep_freeze"

module Pakyow
  module Data
    class Subscribers
      module Adapters
        # Manages data subscriptions in redis.
        #
        # Use this in production.
        #
        # @api private
        class Redis
          class << self
            def stringify_subscription(subscription)
              Zlib::Deflate.deflate(Marshal.dump(subscription))
            end

            def generate_subscription_id(subscription_string)
              Digest::SHA1.hexdigest(subscription_string)
            end
          end

          SCRIPTS = %i(register expire persist).freeze
          KEY_PART_SEPARATOR = "/"
          KEY_PREFIX = "data"
          INFINITY = "+inf"

          extend Support::DeepFreeze
          unfreezable :redis

          def initialize(config)
            @redis = ConnectionPool.new(**config[:pool]) {
              ::Redis.new(config[:connection])
            }

            @prefix = [config[:key_prefix], KEY_PREFIX].join(KEY_PART_SEPARATOR)

            @scripts = {}
            load_scripts

            Concurrent::TimerTask.new(execution_interval: 300, timeout_interval: 300) {
              cleanup
            }.execute
          end

          def register_subscriptions(subscriptions, subscriber:)
            [].tap do |subscription_ids|
              subscriptions.each do |subscription|
                subscription_string = self.class.stringify_subscription(subscription)
                subscription_id = self.class.generate_subscription_id(subscription_string)
                source = subscription[:source]

                @redis.with do |redis|
                  redis.evalsha(@scripts[:register], argv: [
                    @prefix,
                    KEY_PART_SEPARATOR,
                    subscriber.to_s,
                    subscription_id,
                    subscription_string,
                    source.to_s,
                    Time.now.to_i
                  ])
                end

                subscription_ids << subscription_id
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
            @redis.with do |redis|
              redis.evalsha(@scripts[:expire], argv: [
                @prefix,
                KEY_PART_SEPARATOR,
                subscriber.to_s,
                Time.now.to_i + seconds
              ])
            end
          end

          def persist(subscriber)
            @redis.with do |redis|
              redis.evalsha(@scripts[:persist], argv: [
                @prefix,
                KEY_PART_SEPARATOR,
                subscriber.to_s
              ])
            end
          end

          def expiring?(subscriber)
            @redis.with do |redis|
              redis.ttl(key_subscription_ids_by_subscriber(subscriber)) > -1
            end
          end

          def subscribers_for_subscription_id(subscription_id)
            @redis.with do |redis|
              redis.zrangebyscore(
                key_subscribers_by_subscription_id(
                  subscription_id
                ), INFINITY, INFINITY
              ).map(&:to_sym)
            end
          end

          def subscription_ids_for_source(source)
            @redis.with do |redis|
              redis.zrangebyscore(
                key_subscription_ids_by_source(
                  source
                ), INFINITY, INFINITY
              )
            end
          end

          # FIXME: Refactor this into a lua script. We'll want to stop using SCAN and instead store
          # known sources in a set. Cleanup should then be based off the set of known sources and
          # return the number of values that were removed.
          #
          def cleanup
            @redis.with do |redis|
              redis.scan_each(match: key_subscription_ids_by_source("*")) do |key|
                Pakyow.logger.debug "[Pakyow::Data::Subscribers::Adapters::Redis] Cleaning up expired subscriptions for #{key}"
                removed_count = redis.zremrangebyscore(key, 0, Time.now.to_i)
                Pakyow.logger.debug "[Pakyow::Data::Subscribers::Adapters::Redis] Removed #{removed_count} members for #{key}"
              end
            end
          end

          private

          def subscriptions_for_subscription_ids(subscription_ids)
            return [] if subscription_ids.empty?

            @redis.with do |redis|
              redis.mget(subscription_ids.map { |subscription_id|
                key_subscription_id(subscription_id)
              }).zip(subscription_ids).map { |subscription_string, subscription_id|
                begin
                  Marshal.restore(Zlib::Inflate.inflate(subscription_string)).tap do |subscription|
                    subscription[:id] = subscription_id
                  end
                rescue TypeError
                  Pakyow.logger.error "could not find subscription for #{subscription_id}"
                  {}
                end
              }
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

          def key_subscription_ids_by_source(source)
            build_key("source:#{source}")
          end

          def key_source_for_subscription_id(subscription_id)
            build_key("subscription:#{subscription_id}", "source")
          end

          def load_scripts
            @redis.with do |redis|
              SCRIPTS.each do |script|
                script_content = File.read(
                  File.expand_path("../redis/scripts/_shared.lua", __FILE__)
                ) + File.read(
                  File.expand_path("../redis/scripts/#{script}.lua", __FILE__)
                )

                @scripts[script] = redis.script(:load, script_content)
              end
            end
          end
        end
      end
    end
  end
end
