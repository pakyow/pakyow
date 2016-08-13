require "singleton"

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

        channels = registry.channels_for_key(key)

        channels.each do |channel|
          next if connection.nil?
          @channels[channel] ||= []

          next if @channels[channel].include?(connection)
          @channels[channel] << connection
        end

        registry.subscribe_for_propagation(channels, key) if registry.propagates?
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
        if registry.propagates? && !propagated?(message)
          return propagate(message, channels)
        elsif propagated?(message)
          message.delete(:__propagated)
        end

        # push to this instances connections
        channels.each do |channel_query|
          connections_for_channel(channel_query).each_pair do |channel, conns|
            conns.each do |connection|
              connection.push(payload: message, channel: channel)
            end
          end
        end
      end

      # Pushes a message down a channel to a specific client (identified by key).
      def push_message_to_socket_with_key(message, channel, key, propagated = false)
        return if key.nil? || key.empty?

        if registry.propagates? && !propagated
          return registry.push_message_to_socket_with_key(message, channel, key)
        else
          connection = @connections.find { |_, connection|
            connection and connection.key == key
          }

          if connection
            connection[1].write(payload: message, channel: channel)
          end
        end
      end

      private

      def propagate(message, channels)
        registry.propagate(message, channels)
      end

      def propagated?(message)
        message.include?(:__propagated) || message.include?('__propagated')
      end

      def connections_for_channel(channel_query)
        regexp = Regexp.new("^#{channel_query.to_s.gsub('*', '([^;]*)')}$")

        @channels.select { |channel, _conns|
          channel.match(regexp)
        }
      end
    end
  end
end
