# frozen_string_literal: true

module Pakyow
  class Application
    module Helpers
      module Realtime
        module Socket
          def socket_client_id
            @connection.get(:__socket_client_id)
          end
        end
      end
    end
  end
end
