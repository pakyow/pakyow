require 'redis'

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

        Thread.new {
          @redis.subscribe(*channels) do |on|
            on.message do |channel, msg|
              begin
                msg = JSON.parse(msg)

                if channel == signal_channel
                  if msg['signal'] == SIGNAL_UNSUBSCRIBE
                    @resubscribe_channels = msg['resubscribe_channels']
                    @redis.unsubscribe
                  end
                end

                if msg.is_a?(Hash)
                  msg[:__propagated] = true
                elsif msg.is_a?(Array)
                  msg << :__propagated
                end

                context = Pakyow::Realtime::Context.new(Pakyow.app)

                if msg.key?('key')
                  context.push_message_to_socket_with_key(msg['message'], msg['channel'], msg['key'], true)
                else
                  context.push(msg, channel)
                end
              rescue StandardError => e
                Pakyow.logger.error "RedisSubscription encountered a fatal error:"
                Pakyow.logger.error e.message
              end
            end
          end

          subscribe(@resubscribe_channels) if @resubscribe_channels
        }
      end

      def signal_channel
        "pw:#{object_id}:signal"
      end
    end
  end
end
