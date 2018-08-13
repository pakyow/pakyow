# frozen_string_literal: true

require "pakyow/support/message_verifier"

module Pakyow
  module Security
    module Helpers
      module CSRF
        def authenticity_server_id
          return @connection.params[:authenticity_server_id] if @connection.params[:authenticity_server_id]
          @connection.session[:authenticity_server_id] ||= Support::MessageVerifier.key
        end

        def authenticity_client_id
          return @connection.params[:authenticity_client_id] if @connection.params[:authenticity_client_id]
          @authenticity_client_id ||= Support::MessageVerifier.key
        end

        def authenticity_digest(authenticity_client_id)
          Support::MessageVerifier.digest(authenticity_client_id, key: authenticity_server_id)
        end
      end
    end
  end
end
