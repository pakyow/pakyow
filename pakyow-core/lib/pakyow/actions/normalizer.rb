# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Actions
    # Normalizes request uris, issuing a 301 redirect to the normalized uri.
    #
    class Normalizer
      using Support::Refinements::String::Normalization

      def call(connection)
        path = connection.request_header("PATH_INFO")
        host = connection.request_header("SERVER_NAME")

        if strict_www? && require_www? && !www?(host) && !subdomain?(host)
          redirect!(connection, File.join(add_www(host), path))
        elsif strict_www? && !require_www? && www?(host)
          redirect!(connection, File.join(remove_www(host), path))
        elsif strict_path? && slash?(path)
          redirect!(connection, String.normalize_path(path))
        end
      end

      private

      def redirect!(connection, location)
        connection.status = 301
        connection.set_response_header("Location", location)
        connection.halt
      end

      def add_www(host)
        "www.#{host}"
      end

      def remove_www(host)
        host.split(".")[1..-1].join(".")
      end

      def slash?(path)
        double_slash?(path) || tail_slash?(path)
      end

      def double_slash?(path)
        path.include?("//")
      end

      TAIL_SLASH_REGEX = /(.)+(\/)+$/

      def tail_slash?(path)
        (TAIL_SLASH_REGEX =~ path).nil? ? false : true
      end

      def subdomain?(host)
        host.split(".").size > 2
      end

      def www?(host)
        host.split(".").first == "www"
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
    end
  end
end
