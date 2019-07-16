# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Realtime
        module Broadcasting
          def broadcast(message)
            app.websocket_server.subscription_broadcast(socket_client_id, message)
          end
        end
      end
    end
  end
end
