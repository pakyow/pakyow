# frozen_string_literal: true

require "uri"

require "pakyow/core/security/base"

module Pakyow
  module Security
    module CSRF
      # Protects against Cross-Site Forgery Requests (CSRF).
      # https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
      #
      # Allows requests whose origin header matches the request uri, or the origin is contained in
      # +config.origin.whitelist+. Additionally, the request referrer must match the request host.
      # Empty referrer values are allowed by default but can be restricted by setting
      # +config.referrer.allow_empty+ to +false+.
      #
      class VerifySameOrigin < Base
        def allowed?(connection)
          allowed_origin?(connection) && allowed_referrer?(connection)
        end

        protected

        def allowed_origin?(connection)
          whitelisted_origin?(connection) || matching_origin?(connection)
        end

        def allowed_referrer?(connection)
          empty_and_allowable_referrer?(connection) || matching_referrer?(connection)
        end

        def whitelisted_origin?(connection)
          @config[:origin_whitelist].to_a.include?(connection.request.env["HTTP_ORIGIN"])
        end

        def matching_origin?(connection)
          connection.request.env["HTTP_ORIGIN"] == connection.request.base_url
        end

        def empty_and_allowable_referrer?(connection)
          connection.request.env["HTTP_REFERER"].to_s.empty? && @config[:allow_empty_referrer]
        end

        # rubocop:disable Lint/HandleExceptions
        def matching_referrer?(connection)
          URI.parse(connection.request.env["HTTP_REFERER"]).host == connection.request.host
        rescue URI::InvalidURIError
        end
        # rubocop:enable Lint/HandleExceptions
      end
    end
  end
end
