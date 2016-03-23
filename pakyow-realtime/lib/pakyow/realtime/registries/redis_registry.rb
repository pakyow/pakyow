require 'json'
require 'redis'
require 'singleton'

require 'pakyow/realtime/redis_subscription'
require 'pakyow/realtime/registries/simple_registry'

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
    class RedisRegistry < SimpleRegistry
      attr_reader :subscriber

      def channels_for_key(key)
        value = Pakyow::Realtime.redis.hget(channel_key, key)
        value ? JSON.parse(value) : []
      end

      def unregister_key(key)
        super

        Pakyow::Realtime.redis.hdel(channel_key, key)
        resubscribe
      end

      def subscribe_to_channels_for_key(channels, key)
        channels << "pw:socket:#{key}"
        super

        resubscribe

        new_channels = channels_for_key(key).concat(Array.ensure(channels)).uniq
        Pakyow::Realtime.redis.hset(channel_key, key, new_channels.to_json)
      end

      def unsubscribe_to_channels_for_key(channels, key)
        super

        resubscribe

        new_channels = channels_for_key(key) - Array.ensure(channels)
        Pakyow::Realtime.redis.hset(channel_key, key, new_channels.to_json)
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

      def subscribe_for_propagation(channels, key)
        @channels[key] ||= []
        @channels[key].concat(Array.ensure(channels)) << "pw:socket:#{key}"
        @channels[key].uniq!

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

      # Tells the subscription to unsubscribe from the current
      # list of channels, then subscribes it to the new list.
      def resubscribe
        channels = @channels.values.flatten.uniq

        if @subscriber
          Pakyow::Realtime.redis.publish(@subscriber.signal_channel, {
            'signal' => RedisSubscription::SIGNAL_UNSUBSCRIBE,
            'resubscribe_channels' => channels
          }.to_json)
        else
          @subscriber = RedisSubscription.new
          @subscriber.subscribe(channels)
        end
      end

      # Returns the key used to store channels.
      def channel_key
        Config.realtime.redis_key
      end
    end
  end
end
