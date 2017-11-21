# frozen_string_literal: true

require "redis"

module Pakyow
  module Realtime
    # Manages channel subscriptions for this application instance's WebSockets.
    #
    # @api private
    class RedisSubscription
      def initialize
        @s_redis = ::Redis.new(Config.realtime.redis)
        @c_redis = ::Redis.new(Config.realtime.redis)
      end

      def subscribe
        Thread.new do
          @s_redis.psubscribe(pubsub_channel("socket", "*", "channel", "*")) do |on|
            on.pmessage do |_pattern, channel, message|
              begin
                _, _, socket_key, _, channel = channel.split(RedisRegistry::PUBSUB_DELIMITER)
                Delegate.instance.push_to_key(message, channel, socket_key, propagated: true)
              rescue StandardError => e
                Pakyow.logger.error "RedisSubscription encountered a fatal error:"
                Pakyow.logger.error e.message
              end
            end
          end
        end

        Thread.new {
          @c_redis.psubscribe(pubsub_channel("channel", "*")) do |on|
            on.pmessage do |_pattern, channel, message|
              begin
                _, _, channel = channel.split(RedisRegistry::PUBSUB_DELIMITER)
                Delegate.instance.push(message, channel, propagated: true)
              rescue StandardError => e
                Pakyow.logger.error "RedisSubscription encountered a fatal error:"
                Pakyow.logger.error e.message
              end
            end
          end
        }
      end

      private

      def pubsub_channel(*values)
        [RedisRegistry::PUBSUB_PREFIX].concat(values).flatten.join(RedisRegistry::PUBSUB_DELIMITER)
      end
    end
  end
end
