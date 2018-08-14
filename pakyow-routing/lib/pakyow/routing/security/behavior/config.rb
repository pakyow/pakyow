# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Security
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          settings_for :security do
            settings_for :csrf do
              setting :protection, {}
              setting :origin_whitelist, []
              setting :allow_empty_referrer, true
              setting :param, :authenticity_token
            end
          end

          require "pakyow/routing/security/csrf/verify_same_origin"
          require "pakyow/routing/security/csrf/verify_authenticity_token"

          config.security.csrf.protection = {
            origin: CSRF::VerifySameOrigin.new(
              origin_whitelist: config.security.csrf.origin_whitelist,
              allow_empty_referrer: config.security.csrf.allow_empty_referrer
            ),

            authenticity: CSRF::VerifyAuthenticityToken.new({}),
          }
        end
      end
    end
  end
end
