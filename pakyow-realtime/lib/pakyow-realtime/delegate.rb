module Pakyow
  module Realtime
    # A singleton for delegating socket traffic using the configured registry.
    #
    # @api private
    class Delegate
      include Singleton

      attr_reader :registry, :connections, :channels

      def initialize
        @registry = Config.realtime.registry.instance

        @connections = {}
        @channels = {}
      end

      # Registers a websocket instance with a unique key.
      def register(key, connection)
        @connections[key] = connection

        registry.channels_for_key(key).each do |channel|
          next if connection.nil?
          @channels[channel] ||= []

          next if @channels[channel].include?(connection)
          @channels[channel] << connection
        end
      end

      # Unregisters a connection by its key.
      def unregister(key)
        registry.unregister_key(key)

        connection = @connections.delete(key)
        @channels.each do |_channel, connections|
          connections.delete(connection)
        end
      end

      # Subscribes a websocket identified by its key to one or more channels.
      def subscribe(key, channels)
        registry.subscribe_to_channels_for_key(channels, key)

        # register the connection again since we've added channels
        register(key, @connections[key])
      end

      # Unsubscribes a websocket identified by its key to one or more channels.
      def unsubscribe(key, channels)
        registry.unsubscribe_to_channels_for_key(channels, key)
      end

      # Pushes a message down channels from server to client.
      def push(message, channels)
        channels.each do |channel_query|
          connections_for_channel(channel_query).each_pair do |channel, conns|
            conns.each do |connection|
              connection.push(payload: message, channel: channel)
            end
          end
        end
      end

      private

      def connections_for_channel(channel_query)
        regexp = Regexp.new("^#{channel_query.to_s.gsub('*', '([^;]*)')}$")

        @channels.select { |channel, _conns|
          channel.match(regexp)
        }
      end
    end
  end
end
