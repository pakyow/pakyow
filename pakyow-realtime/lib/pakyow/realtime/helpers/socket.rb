# frozen_string_literal: true

module Pakyow
  module Realtime
    module Helpers
      module Socket
        def socket_server_id
          return @connection.params[:socket_server_id] if @connection.params[:socket_server_id]
          @connection.session[:socket_server_id] ||= Support::MessageVerifier.key
        end

        def socket_client_id
          return @connection.params[:socket_client_id] if @connection.params[:socket_client_id]

          if @connection.set?(:__socket_client_id)
            @connection.get(:__socket_client_id)
          else
            @connection.set(:__socket_client_id, Support::MessageVerifier.key)
          end
        end

        def socket_digest(socket_client_id)
          Support::MessageVerifier.digest(socket_client_id, key: socket_server_id)
        end
      end
    end
  end
end
