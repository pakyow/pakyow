# frozen_string_literal: true

require "uri"

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Actions
    # Normalizes request uris, issuing a 301 redirect to the normalized uri.
    #
    class Normalizer
      using Support::Refinements::String::Normalization

      def initialize
        @allowed_http_hosts = Pakyow.config.normalizer.allowed_http_hosts
        @require_https = Pakyow.config.normalizer.require_https
        @require_www = Pakyow.config.normalizer.require_www
        @strict_https = Pakyow.config.normalizer.strict_https
        @strict_www = Pakyow.config.normalizer.strict_www
        @strict_path = Pakyow.config.normalizer.strict_path
        @strict_host = false

        if (canonical_uri = Pakyow.config.normalizer.canonical_uri)
          configure_canonical_uri!(canonical_uri)
        end
      end

      def call(connection)
        redirect = false
        redirect_scheme, redirect_host, redirect_path = nil

        if strict_https?
          if require_https?
            unless https?(connection) || http_allowed?(connection)
              redirect = true
              redirect_scheme = "https"
            end
          elsif https?(connection)
            redirect = true
            redirect_scheme = "http"
          end
        end

        if strict_host?
          unless canonical?(connection)
            redirect = true
            redirect_host = @canonical_host
          end
        elsif strict_www?
          if require_www?
            unless www?(connection) || subdomain?(connection)
              redirect = true
              redirect_host = add_www(connection)
            end
          elsif www?(connection)
            redirect = true
            redirect_host = remove_www(connection)
          end
        end

        if strict_path?
          if slash?(connection)
            redirect = true
            redirect_path = String.normalize_path(connection.fullpath)
          end
        end

        if redirect
          redirect_uri = "#{redirect_scheme || connection.scheme}://#{File.join(redirect_host || connection.authority, redirect_path || connection.fullpath)}"

          connection.status = 301
          connection.set_header("Location", redirect_uri)
          connection.halt
        end
      end

      private

      def configure_canonical_uri!(canonical_uri)
        @canonical_uri = if canonical_uri.is_a?(URI)
          canonical_uri
        else
          URI(canonical_uri)
        end

        @canonical_host = @canonical_uri.host
        @require_https = @canonical_uri.scheme == "https"
        @require_www = false
        @strict_host = true
      end

      def add_www(connection)
        "www.#{connection.authority}"
      end

      def remove_www(connection)
        connection.authority.split(".", 2)[1]
      end

      def slash?(connection)
        double_slash?(connection) || tail_slash?(connection)
      end

      def double_slash?(connection)
        connection.path.include?("//")
      end

      TAIL_SLASH_REGEX = /(.)+(\/)+$/

      def tail_slash?(connection)
        !(TAIL_SLASH_REGEX =~ connection.path).nil?
      end

      def subdomain?(connection)
        connection.host.count(".") > 1
      end

      def www?(connection)
        connection.subdomain == "www"
      end

      def https?(connection)
        connection.secure?
      end

      def strict_path?
        @strict_path == true
      end

      def strict_www?
        @strict_www == true
      end

      def require_www?
        @require_www == true
      end

      def strict_https?
        @strict_https == true
      end

      def require_https?
        @require_https == true
      end

      def http_allowed?(connection)
        @allowed_http_hosts.include?(connection.host)
      end

      def strict_host?
        @strict_host == true
      end

      def canonical?(connection)
        connection.host == @canonical_host
      end
    end
  end
end
