require 'singleton'

module Pakyow
  module Realtime
    # Manages WebSocket connections and their subscriptions in memory.
    #
    # Intended only for use in development or single app-instance deployments.
    #
    # @api private
    class SimpleRegistry
      include Singleton

      def initialize
        @channels = {}
      end

      def channels_for_key(key)
        @channels.fetch(key, [])
      end

      def unregister_key(key)
        @channels.delete(key)
      end

      def subscribe_to_channels_for_key(channels, key)
        @channels[key] ||= []
        @channels[key].concat(Array.ensure(channels)).uniq!
      end

      def unsubscribe_to_channels_for_key(channels, key)
        @channels[key] ||= []
        @channels[key] = @channels[key] - Array.ensure(channels)
      end

      def propagates?
        false
      end
    end
  end
end
