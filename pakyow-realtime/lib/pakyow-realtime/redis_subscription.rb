require 'redis'
require 'concurrent'

module Pakyow
  module Realtime
    # Manages channel subscriptions for this application instance's WebSockets.
    #
    # @api private
    class RedisSubscription
      SIGNAL_UNSUBSCRIBE = 'unsubscribe'

      def initialize
        @redis = ::Redis.new(Config.realtime.redis)
      end

      def subscribe(channels = [])
        channels << signal_channel

        Concurrent::Future.execute {
          @redis.subscribe(*channels) do |on|
            on.message do |channel, msg|
              if channel == signal_channel
                if msg == SIGNAL_UNSUBSCRIBE
                  @redis.unsubscribe
                  return
                end
              end

              msg = JSON.parse(msg)

              if msg.is_a?(Hash)
                msg[:__propagated] = true
              elsif msg.is_a?(Array)
                msg << :__propagated
              end

              context = Pakyow::Realtime::Context.new(Pakyow.app)

              if msg.key?('key')
                context.push_message_to_socket_with_key(msg['message'], msg['channel'], msg['key'])
              else
                context.push(msg, channel)
              end
            end
          end
        }
      end

      def signal_channel
        "pw:#{object_id}:signal"
      end
    end
  end
end
