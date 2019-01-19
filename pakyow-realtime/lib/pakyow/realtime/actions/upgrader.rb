# frozen_string_literal: true

require "websocket/driver"

require "pakyow/support/message_verifier"

require "pakyow/realtime/websocket"

module Pakyow
  module Realtime
    module Actions
      class Upgrader
        def call(connection)
          if websocket?(connection)
            WebSocket.new(connection.verifier.verify(connection.params[:id]), connection)
            connection.halt
          end
        rescue Support::MessageVerifier::TamperedMessage
          connection.status = :forbidden
          connection.halt
        end

        private

        def websocket?(connection)
          websocket_path?(connection) && smells_like_a_websocket?(connection)
        end

        def websocket_path?(connection)
          connection.path == "/pw-socket"
        end

        def smells_like_a_websocket?(connection)
          ::WebSocket::Driver.websocket?(connection.env)
        end
      end
    end
  end
end
