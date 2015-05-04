require 'json'
require 'redis'
require 'singleton'

require_relative '../redis_subscription'

module Pakyow
  module Realtime
    # A singleton for managing connections of some type (e.g. websockets) in redis.
    #
    # This is intended to be the default registry in production systems.
    #
    # @api private
    class RedisRegistry
      include Singleton

      def initialize
        @redis = Redis.new(Config.realtime.redis)
      end

      def channels_for_key(key)
        channels(key)
      end

      def unregister_key(key)
        @redis.hdel(channel_key, key)
      end

      def subscribe_to_channels_for_key(channels, key)
        new_channels = channels(key).concat(Array.ensure(channels)).uniq
        @redis.hset(channel_key, key, new_channels.to_json)
        resubscribe(new_channels)
      end

      def unsubscribe_to_channels_for_key(channels, key)
        new_channels = channels(key) - Array.ensure(channels)
        @redis.hset(channel_key, key, new_channels.to_json)
        resubscribe(new_channels)
      end

      private

      # Terminates the current subscriber and creates a new
      # subscriper with the current channels.
      def resubscribe(channels)
        @subscriber.terminate if @subscriber
        @subscriber = RedisSubscription.new
        @subscriber.subscribe(channels)
      end

      # Returns the key used to store channels.
      def channel_key
        Config.realtime.redis_key
      end

      # Returns the channels for a specific key, or all channels.
      def channels(key)
        value = @redis.hget(channel_key, key)
        (value ? JSON.parse(value) : []).map { |channel| channel.to_sym }
      end
    end
  end
end
