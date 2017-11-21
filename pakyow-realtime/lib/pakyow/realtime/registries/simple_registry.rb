# frozen_string_literal: true

require "singleton"

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

      def subscribe_to_channels_for_key(*channels, key)
        @channels[key] ||= []
        @channels[key].concat(channels).uniq!
      end

      def unsubscribe_from_channels_for_key(*channels, key)
        @channels[key] ||= []
        @channels[key] = @channels[key] - channels
      end

      def propagate(message, *channels)
        channels.each do |channel|
          pmessage = { payload: message, channel: channel }
          Delegate.instance.push(pmessage.to_json, *channels, propagated: true)
        end
      end

      def push_to_key(message, channel, key)
        pmessage = { payload: message, channel: channel }
        Delegate.instance.push_to_key(pmessage.to_json, channel, key, propagated: true)
      end
    end
  end
end
