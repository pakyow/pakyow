require "pakyow/core/call_context"
require "pakyow/core/helpers"
require "pakyow/core/loader"
require "pakyow/core/router"

require "pakyow/support/configurable"
require "pakyow/support/defineable"
require "pakyow/support/hookable"

require "pakyow/core/config/app"

# some playing around with a simpler routing approach
# class NewRouter
#   attr_reader :routes

#   METHOD_GET    = "GET".freeze
#   METHOD_POST   = "POST".freeze
#   METHOD_PUT    = "PUT".freeze
#   METHOD_PATCH  = "PATCH".freeze
#   METHOD_DELETE = "DELETE".freeze

#   SUPPORTED_METHODS = [
#     METHOD_GET,
#     METHOD_POST,
#     METHOD_PUT,
#     METHOD_PATCH,
#     METHOD_DELETE
#   ].freeze

#   REQUEST_METHOD = "REQUEST_METHOD".freeze
#   PATH_INFO = "PATH_INFO".freeze

#   def initialize
#     @routes = {}
#     SUPPORTED_METHODS.each do |method|
#       @routes[method] = []
#     end
#   end

#   def default(&block)
#     routes[METHOD_GET] << Route.new("/", &block)
#   end

#   def call(app_call, env)
#     route = routes[env[REQUEST_METHOD]].find do |route|
#       route.match?(PATH_INFO)
#     end

#     route.call(app_call, env) if route
#   end
# end

# class Route
#   attr_reader :path

#   def initialize(path, &block)
#     @path = path
#     @block = block
#   end

#   def match?(path_to_match)
#     case path
#     when Regexp
#       if data = path.match(path_to_match)
#         return data
#       end
#     when String
#       if path == path_to_match
#         return true
#       end
#     end

#     false
#   end

#   def call(app_call, env)
#     app_call.instance_eval(&@block)
#   end
# end

module Pakyow
  # The main app object.
  #
  # @api public
  class App
    include Support::Defineable
    include Support::Hookable

    known_events :init, :configure, :load, :reload, :fork

    stateful :routes, RouteSet

    attr_reader :env, :builder

    class << self
      # Defines a resource.
      #
      # @api public
      def resource(set_name, path, &block)
        raise ArgumentError, 'Expected a block' unless block_given?

        # TODO: move this to a define_resource hook
        RESOURCE_ACTIONS.each do |plugin, action|
          action.call(self, set_name, path, block)
        end
      end

      RESOURCE_ACTIONS = {
        core: Proc.new do |app, set_name, path, block|
          app.routes set_name do
            restful(set_name, path, &block)
          end
        end
      }
    end

    def initialize(env: nil, builder: nil)
      @env = env
      @builder = builder

      hook_around :configure do
        use_config(env)
      end

      # TODO: this will go away
      Pakyow.app = self

      @loader = Loader.new

      hook_around :init do
        load_app
      end

      super()
    end

    def use(middleware, *args)
      builder.use(middleware, *args)
    end

    # @api private
    def call(env)
      # TODO: I think I like duping self more than I do this
      CallContext.new(self, env).process.finish
    end

    protected

    def load_app
      hook_around :load do
        @loader.load_from_path(config.app.src)
      end
    end
  end
end
