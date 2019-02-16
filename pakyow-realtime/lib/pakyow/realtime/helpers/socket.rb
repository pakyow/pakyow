# frozen_string_literal: true

module Pakyow
  module Realtime
    module Helpers
      module Socket
        def socket_client_id
          @connection.get(:__socket_client_id)
        end
      end
    end
  end
end
