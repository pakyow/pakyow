# frozen_string_literal: true

require "uri"

require "pakyow/security/middleware/base"

module Pakyow
  module Security
    module Middleware
      # Protects against Cross-Site Forgery Requests (CSRF).
      # https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
      #
      # Allows requests whose origin header matches the request uri, or the origin is contained in
      # +config.origin.whitelist+. Additionally, the request referrer must match the request host.
      # Empty referrer values are allowed by default but can be restricted by setting
      # +config.referrer.allow_empty+ to +false+.
      #
      class CSRF < Base
        settings_for :origin do
          setting :whitelist, []
        end

        settings_for :referrer do
          setting :allow_empty, true
        end

        def allowed?(env)
          allowed_origin?(env) && allowed_referrer?(env)
        end

        def allowed_origin?(env)
          whitelisted_origin?(env) || matching_origin?(env)
        end

        def allowed_referrer?(env)
          empty_and_allowable_referrer?(env) || matching_referrer?(env)
        end

        def whitelisted_origin?(env)
          config.origin.whitelist.include?(env["HTTP_ORIGIN"])
        end

        def matching_origin?(env)
          env["HTTP_ORIGIN"] == Rack::Request.new(env).base_url
        end

        def empty_and_allowable_referrer?(env)
          env["HTTP_REFERER"].to_s.empty? && config.referrer.allow_empty
        end

        def matching_referrer?(env)
          URI.parse(env["HTTP_REFERER"]).host == Rack::Request.new(env).host
        rescue URI::InvalidURIError
        end
      end
    end
  end
end
