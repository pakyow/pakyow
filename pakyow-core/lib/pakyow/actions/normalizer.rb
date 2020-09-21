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
        if (canonical_uri = Pakyow.config.normalizer.canonical_uri)
          configure_canonical_uri!(canonical_uri)
        end
      end

      def call(connection)
        if strict_https? && require_https? && !https?(connection)
          unless http_allowed?(connection)
            redirect!(connection, "https://#{File.join(connection.authority, connection.fullpath)}")
          end
        elsif strict_https? && !require_https? && https?(connection)
          redirect!(connection, "http://#{File.join(connection.authority, connection.fullpath)}")
        elsif strict_host? && !canonical?(connection)
          redirect!(connection, "#{connection.scheme}://#{File.join(@canonical_uri.host, connection.fullpath)}")
        elsif strict_www? && require_www? && !www?(connection) && !subdomain?(connection)
          redirect!(connection, File.join(add_www(connection), connection.fullpath))
        elsif strict_www? && !require_www? && www?(connection)
          redirect!(connection, File.join(remove_www(connection), connection.fullpath))
        elsif strict_path? && slash?(connection)
          redirect!(connection, String.normalize_path(connection.fullpath))
        end
      end

      private

      def configure_canonical_uri!(canonical_uri)
        @canonical_uri = if canonical_uri.is_a?(URI)
          canonical_uri
        else
          URI(canonical_uri)
        end

        Pakyow.config.normalizer.require_https = @canonical_uri.scheme == "https"
        Pakyow.config.normalizer.require_www = false
      end

      def redirect!(connection, location)
        connection.status = 301
        connection.set_header("Location", location)
        connection.halt
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
        Pakyow.config.normalizer.strict_path == true
      end

      def strict_www?
        Pakyow.config.normalizer.strict_www == true
      end

      def require_www?
        Pakyow.config.normalizer.require_www == true
      end

      def strict_https?
        Pakyow.config.normalizer.strict_https == true
      end

      def require_https?
        Pakyow.config.normalizer.require_https == true
      end

      def http_allowed?(connection)
        Pakyow.config.normalizer.allowed_http_hosts.include?(connection.host)
      end

      def strict_host?
        instance_variable_defined?(:@canonical_uri)
      end

      def canonical?(connection)
        connection.host == @canonical_uri.host
      end
    end
  end
end
