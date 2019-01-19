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
            WebSocket.new(id, connection)
            connection.halt
          end
        end

        private

        def websocket?(connection)
          websocket_path?(connection) && smells_like_a_websocket?(connection) && verified?(connection)
        end

        def websocket_path?(connection)
          connection.path == "/pw-socket"
        end

        def smells_like_a_websocket?(connection)
          ::WebSocket::Driver.websocket?(connection.env)
        end

        def verified?(connection)
          Support::MessageVerifier.verify(
            connection.params[:id], key: connection.session[:socket_server_id]
          )
        end
      end
    end
  end
end
