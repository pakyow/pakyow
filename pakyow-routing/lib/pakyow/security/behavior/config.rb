# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Security
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          configurable :security do
            configurable :csrf do
              setting :protection, {}
              setting :origin_whitelist, []
              setting :param, :authenticity_token
            end
          end

          require "pakyow/security/csrf/verify_same_origin"
          require "pakyow/security/csrf/verify_authenticity_token"

          config.security.csrf.protection = {
            origin: CSRF::VerifySameOrigin.new(
              origin_whitelist: config.security.csrf.origin_whitelist
            ),

            authenticity: CSRF::VerifyAuthenticityToken.new({}),
          }
        end
      end
    end
  end
end
