module Pakyow
  module Realtime
    # A registry for message handlers. Handlers subscribe to some websocket
    # action and handle incoming messages for that action, returning a response.
    #
    # @api public
    class MessageHandler
      # Registers a handler for some action name.
      #
      # @api public
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
          raise MissingMessageHandler.new("Could not find message handler named #{action}")
        }

        handler.call(message, session, {
          id: message['id']
        })
      end
    end
  end
end
