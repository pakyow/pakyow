require 'json'
require 'redis'
require 'singleton'

require 'pakyow/realtime/redis_subscription'
require 'pakyow/realtime/registries/simple_registry'

module Pakyow
  module Realtime
    def self.redis
      @redis ||= Redis.new(Config.realtime.redis)
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
      
      # The number of publish commands to pipeline to redis.
      #
      PUBLISH_BUFFER_SIZE = 1_000
      
      # How often the publish buffer should be flushed.
      #
      PUBLISH_BUFFER_FLUSH_MS = 150
      
      PUBSUB_DELIMITER = "."
      PUBSUB_PREFIX = "pw"
      PUBSUB_CHANNEL = "channel"
      PUBSUB_SOCKET = "socket"
      
      def initialize
        @subscriber = RedisSubscription.new
        @subscriber.subscribe
        @mutex = Mutex.new
        
        # Contains tuples values e.g. [channel, message]
        @messages = []
      end

      def channels_for_key(key)
        Pakyow::Realtime.redis.sscan_each(channel_for_socket(key)).to_a
      end

      def unregister_key(key)
        Pakyow::Realtime.redis.del(channel_for_socket(key))
      end

      def subscribe_to_channels_for_key(*channels, key)
        Pakyow::Realtime.redis.sadd(channel_for_socket(key), *channels)
      end

      def unsubscribe_from_channels_for_key(*channels, key)
        Pakyow::Realtime.redis.srem(channel_for_socket(key), *channels)
      end

      def propagate(message, *channels)
        channels.each do |channel|
          pmessage = { payload: message, channel: channel }
          publish_message_on_channel(pmessage, pubsub_channel(PUBSUB_CHANNEL => channel))
        end
      end

      def push_to_key(message, channel, key)
        pmessage = { payload: message, channel: channel }
        publish_message_on_channel(pmessage, pubsub_channel(PUBSUB_SOCKET => key, PUBSUB_CHANNEL => channel))
      end

      private

      # Returns the key used to store channels for a given socket key.
      #
      def channel_for_socket(key)
        "#{Config.realtime.redis_key}:#{key}"
      end
      
      def pubsub_channel(values)
        [PUBSUB_PREFIX].concat(values.to_a).flatten.join(PUBSUB_DELIMITER)
      end
      
      def publish_message_on_channel(message, channel)
        @messages << [channel, message.to_json]
        publish_messages
      end
      
      def publish_messages
        if @messages.count > PUBLISH_BUFFER_SIZE
          flush
        end
        
        return if @timer && @timer.alive?
        @timer = Thread.new do
          loop do
            sleep PUBLISH_BUFFER_FLUSH_MS / 1_000
            flush
          end
        end
      end
      
      def flush
        return if @messages.empty?

        @mutex.synchronize do
          Pakyow::Realtime.redis.pipelined do
            until @messages.empty?
              m = @messages.shift
              Pakyow::Realtime.redis.publish(m[0], m[1])
            end
          end
        end
      end
    end
  end
end
