# frozen_string_literal: true

module Pakyow
  module Realtime
    # Deals with realtime connections in context of an app. Instances are
    # returned by the `socket` helper method during routing.
    #
    # @api public
    class Context
      # @api private
      def initialize(app)
        @app = app
      end

      # Subscribe the current session's connection to one or more channels.
      #
      # @api public
      def subscribe(*channels)
        delegate.subscribe(
          @app.socket_digest(@app.socket_connection_id),
          *channels
        )
      end

      # Unsubscribe the current session's connection to one or more channels.
      #
      # @api public
      def unsubscribe(*channels)
        delegate.unsubscribe(
          @app.socket_digest(@app.socket_connection_id),
          *channels
        )
      end

      # Push a message down one or more channels.
      #
      # @api public
      def push(msg, *channels)
        delegate.push(msg, *channels)
      end

      # Push a message down a channel directed at a specific client,
      # identified by key.
      #
      # @api public
      def push_to_key(msg, channel, key, propagated: false)
        delegate.push_to_key(msg, channel, key, propagated: propagated)
      end

      # Returns an instance of the connection delegate.
      #
      # @api private
      def delegate
        Delegate.instance
      end
    end
  end
end
