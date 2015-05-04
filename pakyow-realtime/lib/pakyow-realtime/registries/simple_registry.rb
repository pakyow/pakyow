require 'singleton'

module Pakyow
  module Realtime
    # A singleton for managing connections of some type (e.g. websockets).
    #
    # Not intended to be used in production.
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
        @channels[key].concat(Array.ensure(channels.map { |channel| channel.to_sym })).uniq!
      end

      def unsubscribe_to_channels_for_key(channels, key)
        @channels[key] ||= []
        @channels[key] = @channels[key] - Array.ensure(channels.map { |channel| channel.to_sym })
      end
    end
  end
end
