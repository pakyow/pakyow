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
        @handlers ||= {}
        @handlers[name.to_sym] = block
      end

      # Calls a handler for a received websocket message.
      #
      # @api private
      def self.handle(message, session)
        action = message['action']

        handler = @handlers.fetch(action.to_sym) {
          fail MissingMessageHandler "No message handler named #{action}"
        }

        handler.call(message, session, id: message['id'])
      end
    end
  end
end
