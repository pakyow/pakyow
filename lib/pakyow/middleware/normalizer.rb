# frozen_string_literal: true

require "pakyow/support/string"

module Pakyow
  module Middleware
    # Rack compatible middleware that normalizes requests by:
    #
    # - removing trailing "/" from request paths
    # - adding or removing the "www" subdomain
    #
    # When conditions are met, a 301 redirect will be issued to
    # the normalized destination.
    #
    # @api public
    class Normalizer
      # @api private
      def initialize(app)
        @app = app
      end

      # @api private
      def call(env)
        path = env[Rack::PATH_INFO]
        host = env[Rack::SERVER_NAME]

        if strict_www? && require_www? && !www?(host) && !subdomain?(host)
          [301, { "Location" => File.join(add_www(host), path) }, []]
        elsif strict_www? && !require_www? && www?(host)
          [301, { "Location" => File.join(remove_www(host), path) }, []]
        elsif strict_path? && slash?(path)
          [301, { "Location" => String.normalize_path(path) }, []]
        else
          @app.call(env)
        end
      end

      protected

      TAIL_SLASH_REGEX = /(.)+(\/)+$/

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
