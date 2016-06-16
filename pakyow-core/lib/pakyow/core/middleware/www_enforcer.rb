require 'pakyow/core/call_context'

module Pakyow
  module Middleware
    Pakyow::App.middleware do |builder|
      builder.use Pakyow::Middleware::WWWEnforcer if Pakyow::Config.app.enforce_www
    end

    # Rack compatible middleware that checks if www is enforced and the host
    # doesn't start with www. it issues a 301 redirect to the
    # www version, otherwise just pass the request through
    #
    # @api public
    class WWWEnforcer
      def initialize(app)
        @app = app
        @enforce_www = app.enforce_www
      end

      def call(env)
        host = env['SERVER_NAME']
        return catch_and_redirect(env, add_www(host)) if enforce_www_and_not_subdomain?(host)
        @app.call(env)
      end

      def enforce_www_and_not_subdomain?(host)
        @enforce_www == true && !subdomain?(host)
      end

      def subdomain?(host)
        host
          .split('.')
          .size > 2
      end

      def add_www(host)
        # "www.#{host}"
        host
          .split('.')
          .unshift('www')
          .join('.')
      end

      def catch_and_redirect(env, host)
        catch :halt do
          CallContext.new(env).redirect(host, 301)
        end
      end
    end
  end
end
