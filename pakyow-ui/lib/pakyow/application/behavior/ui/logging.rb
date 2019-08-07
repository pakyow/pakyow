# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module UI
        # Logs client-side messages and errors on the server.
        #
        module Logging
          extend Support::Extension

          apply_extension do
            handle_websocket_message :log do |payload|
              Logging.log(payload, self)
            end
          end

          # @api private
          def self.log(payload, socket)
            socket.logger.public_send(payload["severity"], payload["message"])
          end
        end
      end
    end
  end
end
