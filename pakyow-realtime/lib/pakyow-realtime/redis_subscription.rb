require 'redis'
require 'concurrent'

module Pakyow
  module Realtime
    # Manages channel subscriptions for this application instance's WebSockets.
    #
    # @api private
    class RedisSubscription
      include Concurrent::Async

      def initialize
        @redis = ::Redis.new(Config.realtime.redis)
        @channels = []

        ObjectSpace.define_finalizer(self, self.class.finalize)
      end

      def self.finalize
        -> { unsubscribe }
      end

      def subscribe(channels)
        return if channels.empty?
        @channels = channels

        run
      end

      def unsubscribe
        return if @channels.empty?
        @redis.unsubscribe(*@channels)
      end

      private

      def run
        @redis.subscribe(*@channels) do |on|
          on.message do |channel, msg|
            msg = JSON.parse(msg)

            if msg.is_a?(Hash)
              msg[:__propagated] = true
            elsif msg.is_a?(Array)
              msg << :__propagated
            end

            context = Pakyow::Realtime::Context.new(Pakyow.app)
            context.push(msg, channel)
          end
        end
      end
    end
  end
end
