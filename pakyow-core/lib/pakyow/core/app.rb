require "pakyow/support/defineable"
require "pakyow/support/hookable"

require "pakyow/core/helpers"
require "pakyow/core/loader"
require "pakyow/core/router"
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
    stateful :routes, RouteSet

    include Support::Hookable

    # TODO: audit the other events to make sure they make sense
    known_events :init, :configure, :load, :reload, :process, :route, :match, :error

    attr_reader :environment, :builder

    include Helpers

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

    def initialize(environment, builder: nil)
      @environment = environment
      @builder = builder

      hook_around :configure do
        use_config(environment)
      end

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
      dup.process(env)
    end

    protected

    def process(env)
      @request = Request.new(env)
      @response = Response.new

      # setup a context object; used to provide access to the request / response
      # objects without exposing functionality that should only be accessible
      # from within the app call
      @context = AppContext.new(@request, @response)

      # @handling = false

      hook_around :process do
        @found = false

        catch :halt do
          hook_around :route do
            @found = router.perform(context, self) {
              call_hooks :after, :match
            }

            # TODO: part of the new experimental routing
            # @app.routes.each do |router|
            #   @found = router.call(self, @env)

            #   # TODO: we used to do this, but unsure how useful that is today
            #   # call_hooks :after, :match
            # end
          end

          handle(404, false) unless found?
        end
      end
    rescue StandardError => error
      request.error = error

      catch :halt do
        hook_around :error do
          handle(500, false) unless found?
        end
      end
    ensure
      return @response.finish
    end

    def load_app
      @loader = Loader.new
      hook_around :load do
        @loader.load_from_path(config.app.src)
      end
    end

    def router
      Router.instance
    end

    protected

    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, response
    end

    # Routes the request to different logic.
    #
    # TODO: change this to reroute(location, method: request.method)
    def reroute(location, method = nil)
      request.setup(router.path(location), method)
      call_hooks :before, :route
      call_hooks :after, :match
      router.reroute(request)
      call_hooks :after, :route
    end

    # Sends data in the response (immediately). Accepts a string of data or a File,
    # mime-type (auto-detected; defaults to octet-stream), and optional file name.
    #
    # If a File, mime type will be guessed. Otherwise mime type and file name will
    # default to whatever is set in the response.
    #
    # TODO: change this to send(file_or_data, type: nil, as: nil)
    def send(file_or_data, type = nil, send_as = nil)
      if file_or_data.is_a?(IO) || file_or_data.is_a?(StringIO)
        data = file_or_data

        if file_or_data.is_a?(File)
          # auto set type based on file type
          type ||= Rack::Mime.mime_type(File.extname(file_or_data.path))
        end
      elsif file_or_data.is_a?(String)
        data = StringIO.new(file_or_data)
      else
        raise ArgumentError, "Expected an IO or String object"
      end

      response.body = data
      response["Content-Type"] = type if type
      response["Content-disposition"] = "attachment; filename=#{send_as}" if send_as
      halt
    end

    # Redirects to location (immediately).
    #
    # TODO: change this to redirect(location, as: 302)
    def redirect(location, status_code = 302)
      response.status = Rack::Utils.status_code(status_code)
      response["Location"] = router.path(location)
      halt
    end

    # TODO: this `from_logic` bit is required because of how the
    # router is designed; let's try and refactor that out
    def handle(name_or_code, from_logic = true)
      # @handling = true

      hook_around :route do
        # TODO: we need handlers at the router and app level
        # the ones in the router would handle errors originating from one of the contained routes
        # and the ones in the app would be the fallback for when nothing was matched, or no handlers were defined in the route
        router.handle(name_or_code, self, from_logic)
      end
    end

    def found?
      @found == true
    end
  end
end
