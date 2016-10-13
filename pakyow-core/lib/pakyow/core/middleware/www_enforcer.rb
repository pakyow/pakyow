require 'pakyow/core/call_context'

module Pakyow
  module Middleware
    # Rack compatible middleware that checks if www is enforced and the host
    # doesn't start with www. it issues a 301 redirect to the
    # www version, otherwise just pass the request through
    #
    # @api public
    class WWWEnforcer
      def initialize(app)
        @app = app
      end

      def call(env)
        host = env['SERVER_NAME']
        return catch_and_redirect(env, add_www(host)) unless subdomain?(host)
        @app.call(env)
      end

      def subdomain?(host)
        host
          .split('.')
          .size > 2
      end

      def add_www(host)
        "www.#{host}"
      end

      def catch_and_redirect(env, host)
        catch :halt do
          CallContext.new(env).redirect(host, 301)
        end
      end
    end
  end
end
