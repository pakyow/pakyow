# frozen_string_literal: true

require "pakyow/support/message_verifier"

require_relative "../../../realtime/websocket"

module Pakyow
  class Application
    module Actions
      module Realtime
        class Upgrader
          def call(connection)
            if websocket?(connection)
              Pakyow::Realtime::WebSocket.new(connection.verifier.verify(connection.params[:id]), connection)
              connection.halt
            end
          rescue Support::MessageVerifier::TamperedMessage
            connection.status = 403
            connection.halt
          end

          private

          def websocket?(connection)
            connection.path == "/pw-socket"
          end
        end
      end
    end
  end
end
