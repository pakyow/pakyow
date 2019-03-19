# frozen_string_literal: true

require "uri"

require "pakyow/security/base"

module Pakyow
  module Security
    module CSRF
      # Protects against Cross-Site Forgery Requests (CSRF).
      # https://www.owasp.org/index.php/Cross-Site_Request_Forgery_(CSRF)_Prevention_Cheat_Sheet
      #
      # Allows requests if the origin or referer matches the request uri, or is whitelisted through
      # the +config.origin.whitelist+ config option. The request is not allowed if values for both
      # origin and referer are missing.
      #
      #
      class VerifySameOrigin < Base
        def initialize(*)
          super

          @whitelisted_origins = @config[:origin_whitelist].to_a.map { |origin|
            parse_uri(origin)
          }.compact
        end

        def allowed?(connection)
          origin_uris(connection).yield_self { |origins|
            !origins.empty? && origins.all? { |origin|
              whitelisted_origin?(origin) || matching_origin?(origin, connection)
            }
          }
        end

        private

        def origin_uris(connection)
          origins = []

          if connection.request_header?("origin")
            origins.concat(connection.request_header("origin"))
          end

          if connection.request_header?("referer")
            origins << connection.request_header("referer")
          end

          origins.map! { |value| parse_uri(value) }
        end

        def parse_uri(value)
          URI.parse(value.to_s)
        rescue URI::InvalidURIError
          nil
        end

        def uris_match?(uri1, uri2)
          uri1.scheme == uri2.scheme && uri1.host == uri2.host && uri1.port == uri2.port
        end

        def whitelisted_origin?(origin)
          @whitelisted_origins.any? { |whitelisted|
            uris_match?(whitelisted, origin)
          }
        end

        def matching_origin?(origin, connection)
          uris_match?(origin, parse_uri("#{connection.scheme}://#{connection.authority}"))
        end
      end
    end
  end
end
