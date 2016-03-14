require 'json'
require 'redis'
require 'singleton'

require_relative '../redis_subscription'

module Pakyow
  module Realtime
    def self.redis
      $redis ||= Redis.new(Config.realtime.redis)
    end
    # Manages WebSocket connections and their subscriptions in Redis.
    #
    # This is the default registry in production systems and is required in
    # deployments with more than one app instance.
    #
    # @api private
    class RedisRegistry
      include Singleton

      attr_reader :subscriber

      def initialize
        @channels = []
      end

      def channels_for_key(key)
        channels(key)
      end

      def unregister_key(key)
        Pakyow::Realtime.redis.hdel(channel_key, key)
        @channels.delete("pw:socket:#{key}")
      end

      def subscribe_to_channels_for_key(channels, key)
        new_channels = channels(key).concat(Array.ensure(channels)).uniq
        Pakyow::Realtime.redis.hset(channel_key, key, new_channels.to_json)

        @channels.concat(channels).uniq!
        resubscribe

        @channels << "pw:socket:#{key}"
      end

      def unsubscribe_to_channels_for_key(channels, key)
        new_channels = channels(key) - Array.ensure(channels)
        Pakyow::Realtime.redis.hset(channel_key, key, new_channels.to_json)

        channels.each { |channel| @channels.delete(channel) }
        resubscribe
      end

      def propagates?
        true
      end

      def propagate(message, channels)
        message_json = message.to_json

        channels.each do |channel|
          Pakyow::Realtime.redis.publish(channel, message_json)
        end
      end

      def subscribe_for_propagation(channels)
        @channels.concat(channels).uniq!
        resubscribe
      end

      def push_message_to_socket_with_key(message, channel, key)
        propagate({
          key: key,
          channel: channel,
          message: message
        },

        ["pw:socket:#{key}"])
      end

      private

      # Terminates the current subscriber and creates a new
      # subscriber with the current channels.
      def resubscribe
        if @subscriber
          Pakyow::Realtime.redis.publish(@subscriber.signal_channel, RedisSubscription::SIGNAL_UNSUBSCRIBE)
        else
          @subscriber = RedisSubscription.new
        end

        @subscriber.subscribe(@channels)
      end

      # Returns the key used to store channels.
      def channel_key
        Config.realtime.redis_key
      end

      # Returns the channels for a specific key, or all channels.
      def channels(key)
        value = Pakyow::Realtime.redis.hget(channel_key, key)
        (value ? JSON.parse(value) : []).map(&:to_sym)
      end
    end
  end
end
