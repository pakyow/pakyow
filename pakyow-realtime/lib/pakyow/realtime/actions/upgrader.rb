# frozen_string_literal: true

require "websocket/driver"

require "pakyow/support/message_verifier"

require "pakyow/realtime/websocket"

module Pakyow
  module Realtime
    module Actions
      class Upgrader
        def initialize(_)
        end

        def call(connection)
          return unless Pakyow.config.realtime.server
          return unless connection.path == "/pw-socket"
          return unless ::WebSocket::Driver.websocket?(connection.env)

          # Verify that the websocket is connecting with a valid digest.
          #
          # We expect to receive an id and digest, separated by a colon. The digest is
          # generated from the id along with the key. When the client is a browser, the
          # `id:digest` value is embedded in the response, while the key is stored in
          # the session. We verify by generating the digest and comparing it to the
          # digest sent in the connection attempt.
          id, digest = connection.params[:id].to_s.split(":", 2)
          return unless Support::MessageVerifier.valid?(
            id, digest: digest, key: connection.session[:socket_server_id]
          )

          WebSocket.new(id, connection)
          connection.halt
        end
      end
    end
  end
end
