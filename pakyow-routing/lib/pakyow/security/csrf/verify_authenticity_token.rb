# frozen_string_literal: true

require "pakyow/support/message_verifier"

require "pakyow/security/base"

module Pakyow
  module Security
    module CSRF
      # Protects against Cross-Site Forgery Requests (CSRF).
      # https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
      #
      # Requires a valid token be passed as a request parameter. The token consists
      # of a client id (unique to the request) and a digest generated from the
      # client id and the server id stored in the session.
      #
      # @see Pakyow::Support::MessageVerifier
      #
      class VerifyAuthenticityToken < Base
        def allowed?(connection)
          Support::MessageVerifier.verify(
            connection.params[connection.app.config.security.csrf.param],
            key: connection.session[:authenticity_server_id]
          )
        end
      end
    end
  end
end
