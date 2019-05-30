# frozen_string_literal: true

module Pakyow
  module Realtime
    module Helpers
      module Broadcasting
        def broadcast(message)
          app.websocket_server.subscription_broadcast(socket_client_id, message)
        end
      end
    end
  end
end
