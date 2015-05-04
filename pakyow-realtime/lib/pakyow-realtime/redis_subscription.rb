require 'redis'
require 'celluloid/redis'
require 'celluloid/io'

module Pakyow
  module Realtime
    # Manages subscriptions to channels that this instance's
    # connections belong to.
    #
    # @api private
    class RedisSubscription
      include Celluloid
      include Celluloid::IO

      finalizer :shutdown

      def initialize
        config = Config.realtime.redis
        config[:driver] = :celluloid

        @redis = ::Redis.new(config)
        @channels = []
      end

      def subscribe(channels)
        return if channels.empty?
        @channels = channels
        async.run
      end

      private

      def run
        @redis.subscribe *@channels do |on|
          on.message do |channel, msg|
            RedisRegistry.instance.push(JSON.parse(msg), [channel])
          end
        end
      end

      def shutdown
        return if @channels.empty?
        @redis.unsubscribe(*@channels)
      end
    end
  end
end
