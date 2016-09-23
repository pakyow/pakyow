require 'pakyow/core/call_context'

module Pakyow
  module Middleware
    Pakyow::App.middleware do |builder|
      builder.use Pakyow::Middleware::NonWWWEnforcer unless Pakyow::Config.app.enforce_www
    end

    # Rack compatible middleware that checks if www is not enforced and the host
    # starts with www. it issues a 301 redirect to the
    # non www version, otherwise just pass the request through
    #
    # @api public
    class NonWWWEnforcer
      def initialize(app)
        @app = app
      end

      def call(env)
        host = env['SERVER_NAME']
        return catch_and_redirect(env, remove_www(host)) if www?(host)
        @app.call(env)
      end

      def www?(host)
        host
          .split('.')
          .first == 'www'
      end

      def remove_www(host)
        new_host = host.split('.')
        new_host.shift
        new_host.join('.')
      end

      def catch_and_redirect(env, host)
        catch :halt do
          CallContext.new(env).redirect(host, 301)
        end
      end
    end
  end
end
