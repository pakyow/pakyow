# frozen_string_literal: true

require "pakyow/core/security/base"

module Pakyow
  module Security
    module CSRF
      # Protects against Cross-Site Forgery Requests (CSRF).
      # https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
      #
      # TODO: further description
      #
      class VerifyAuthenticityToken < Base
        def allowed?(_connection)
          true
        end
      end
    end
  end
end
