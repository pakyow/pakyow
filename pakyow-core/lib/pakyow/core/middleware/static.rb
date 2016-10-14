
require 'pakyow/core/call_context'

module Pakyow
  module Middleware
    # Rack compatible middleware that serves static files from one or more configured resource stores.
    #
    # @example
    #   Pakyow::Config.app.resources = {
    #     default: './public'
    #   }
    #
    #   Pakyow::App.builder.use Pakyow::Middleware::Static
    #
    #   # Assuming './public/foo.png' exists, a GET request to '/foo.png' will
    #   # result in this middleware responding with the static file.
    #
    # @api public
    class Static
      def initialize(app)
        @app = app
      end

      def call(env)
        static, resource_path = self.class.static?(env)
        return @app.call(env) unless static

        catch :halt do
          CallContext.new(env).send(File.open(resource_path))
        end
      end

      class << self
        STATIC_REGEX = /\.(.*)$/
        STATIC_HTTP_METHODS = %w(GET)

        # Checks if `path` can be found in any configured resource store.
        #
        # @api public
        def static?(env)
          path, method = env.values_at('PATH_INFO', 'REQUEST_METHOD')

          return false unless STATIC_HTTP_METHODS.include?(method)
          return false unless static_path?(path)

          resources_contain?(path)
        end

        protected

        def static_path?(path)
           path =~ STATIC_REGEX
        end

        def resources_contain?(path)
          resources.each_pair do |_, resource_path|
            full_path = File.join(resource_path, path)
            return true, full_path if File.exist?(full_path)
          end

          false
        end

        def resources
          Config.app.resources
        end
      end
    end
  end
end
