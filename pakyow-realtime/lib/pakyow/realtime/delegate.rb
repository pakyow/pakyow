# frozen_string_literal: true

require "singleton"

module Pakyow
  module Realtime
    # A singleton for delegating socket traffic using the configured registry.
    #
    # @api private
    class Delegate
      attr_reader :registry, :connections, :channels

      def initialize(registry)
        @registry = registry
        @connections = {}
        @channels = {}
      end

      # Registers a websocket instance with a unique key.
      #
      def register(key, connection)
        return if connection.nil?
        @connections[key] = connection

        registry.channels_for_key(key).each do |channel|
          @channels[channel] ||= []

          next if @channels[channel].include?(connection)
          @channels[channel] << connection
        end
      end

      # Unregisters a connection by its key.
      #
      def unregister(key)
        registry.unregister_key(key)

        connection = @connections.delete(key)
        @channels.each do |_channel, connections|
          connections.delete(connection)
        end
      end

      # Subscribes a websocket identified by its key to one or more channels.
      #
      def subscribe(key, *channels)
        registry.subscribe_to_channels_for_key(*channels, key)

        # register the connection again since we've added channels
        if conn = @connections[key]
          register(key, conn)
        end
      end

      # Unsubscribes a websocket identified by its key to one or more channels.
      #
      def unsubscribe(key, *channels)
        registry.unsubscribe_from_channels_for_key(*channels, key)
      end

      # Pushes a message down channels from server to client.
      #
      def push(message, *channels, propagated: false)
        if !propagated
          return registry.propagate(message, *channels)
        end

        # NOTE: Propagated message should be a pushable object (e.g. json).
        channels.each do |channel_query|
          connections_for_channel(channel_query).each_pair do |_channel, conns|
            conns.each do |connection|
              connection.write(message)
            end
          end
        end
      end

      # Pushes a message down a channel to a specific client (identified by key).
      #
      def push_to_key(message, channel, key, propagated: false)
        if !propagated
          return registry.push_to_key(message, channel, key)
        end

        return unless connection = @connections.find { |_, c|
          c.key == key
        }

        # NOTE: Propagated message should be a pushable object (e.g. json).
        connection[1].write(message)
      end

      private

      def connections_for_channel(channel_query)
        channel_query = channel_query

        if channel_query.to_s.include?("*")
          channel_query = Regexp.new("^#{channel_query.to_s.gsub('*', '([^;]*)')}$")
        end

        @channels.select { |channel, _conns|
          if channel_query.is_a?(Regexp)
            channel.match(channel_query)
          else
            channel == channel_query
          end
        }
      end
    end
  end
end
