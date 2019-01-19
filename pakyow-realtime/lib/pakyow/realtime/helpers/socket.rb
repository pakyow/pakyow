# frozen_string_literal: true

module Pakyow
  module Realtime
    module Helpers
      module Socket
        def socket_client_id
          return @connection.params[:socket_client_id] if @connection.params[:socket_client_id]

          if @connection.set?(:__socket_client_id)
            @connection.get(:__socket_client_id)
          else
            @connection.set(:__socket_client_id, Support::MessageVerifier.key)
          end
        end
      end
    end
  end
end
