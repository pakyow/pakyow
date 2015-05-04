require_relative 'websocket'
require_relative 'config'

module Pakyow
  module Realtime
    # A context class for dealing with realtime connections in context of an app.
    #
    # @api public
    class Context
      # @api private
      def initialize(app)
        @app = app
      end

      # Returns an instance of the connection delegate.
      #
      # @api private
      def delegate
        Delegate.instance
      end

      # Subscribe the current session's connection to one or more channels.
      #
      # @api public
      def subscribe(*channels)
        channels = Array.ensure(channels).flatten
        raise ArgumentError if channels.empty?
        delegate.subscribe(@app.socket_digest(@app.socket_connection_id), channels)
      end

      # Unsubscribe the current session's connection to one or more channels.
      #
      # @api public
      def unsubscribe(*channels)
        channels = Array.ensure(channels).flatten
        raise ArgumentError if channels.empty?
        delegate.unsubscribe(@app.socket_digest(@app.socket_connection_id), channels)
      end

      # Push a message down one or more channels.
      #
      # @api public
      def push(msg, *channels)
        channels = Array.ensure(channels).flatten
        raise ArgumentError if channels.empty?
        delegate.push(msg, channels)
      end
    end
  end
end
