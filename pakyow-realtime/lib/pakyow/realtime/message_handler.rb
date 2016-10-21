require_relative 'exceptions'

module Pakyow
  module Realtime
    # Convenience method for registering a new message handler.
    #
    # @api public
    def self.handler(name, &block)
      MessageHandler.register(name, &block)
    end

    # A message handler registry. Handlers subscribe to some action and handle
    # incoming messages for that action, returning a response.
    #
    # @api private
    class MessageHandler
      # Registers a handler for some action name.
      #
      # @api private
      def self.register(name, &block)
        handlers[name.to_sym] = block
      end

      # Calls a handler for a received websocket message.
      #
      # @api private
      def self.handle(message, connection)
        id = message.fetch('id') {
          fail ArgumentError, "Expected message to contain key 'id'"
        }

        action = message.fetch('action') {
          fail ArgumentError, "Expected message to contain key 'action'"
        }

        handler = handlers.fetch(action.to_sym) {
          fail MissingMessageHandler, "No message handler named #{action}"
        }

        handler.call(message, connection, id: id)
      end

      # Resets the message handlers.
      #
      # @api private
      def self.reset
        @handlers = nil
      end

      private

      def self.handlers
        @handlers ||= {}
      end
    end
  end
end
