require "pakyow/support/configurable"
require "pakyow/support/defineable"
require "pakyow/support/hookable"

require "pakyow/core/helpers"
require "pakyow/core/loader"
require "pakyow/core/router"

module Pakyow
  # The main app object.
  #
  # Can be defined once, mounted multiple times.
  #
  # @api public
  class App
    include Support::Defineable
    stateful :router, Router

    include Support::Hookable
    known_events :initialize, :configure, :load, :process, :route, :error

    include Support::Configurable

    settings_for :app, extendable: true do
      setting :name, "pakyow"

      setting :resources do
        @resources ||= {
          default: File.join(config.app.root, "public")
        }
      end

      setting :src do
        File.join(config.app.root, "app", "lib")
      end

      setting :root, File.dirname("")
    end

    settings_for :router do
      setting :enabled, true

      defaults :prototype do
        setting :enabled, false
      end
    end

    settings_for :errors do
      setting :enabled, true

      defaults :production do
        setting :enabled, false
      end

      defaults :ludicrous do
        setting :enabled, false
      end
    end

    settings_for :static do
      setting :enabled, true

      defaults :ludicrous do
        setting :enabled, false
      end
    end

    settings_for :cookies do
      setting :path, "/"

      setting :expiry do
        Time.now + 60 * 60 * 24 * 7
      end
    end

    settings_for :session do
      setting :enabled, true
      setting :object, Rack::Session::Cookie
      setting :old_secret
      setting :expiry
      setting :path
      setting :domain

      setting :options do
        opts = {
          key: config.session.key,
          secret: config.session.secret
        }

        # set optional options if available
        %i(domain path expire_after old_secret).each do |opt|
          value = config.session.send(opt)
          opts[opt] = value if value
        end

        opts
      end

      setting :key do
        "#{config.app.name}.session"
      end

      setting :secret do
        ENV['SESSION_SECRET']
      end
    end

    attr_reader :environment, :builder

    include Helpers

    class << self
      # Defines a resource.
      #
      # @api public
      def resource(name, path, &block)
        raise ArgumentError, "Expected a block" unless block_given?

        # TODO: move this to a define_resource hook
        RESOURCE_ACTIONS.each do |plugin, action|
          action.call(self, name, path, block)
        end
      end

      RESOURCE_ACTIONS = {
        core: Proc.new do |app, name, path, block|
          app.router do
            resource name, path, &block
          end
        end
      }
    end

    def initialize(environment, builder: nil, &block)
      @environment = environment
      @builder = builder

      hook_around :initialize do
        hook_around :configure do
          use_config(environment)
        end

        hook_around :load do
          load_app
        end
      end

      # Call the Pakyow::Defineable initializer.
      # This ensures that any state registered in the passed block
      # has the proper priority against instance and global state.
      super(&block)
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

      # @handling = false

      hook_around :process do
        @found = false

        catch :halt do
          hook_around :route do
            state_for(:router).each do |router|
              @found = router.call(
                @request.env[Rack::PATH_INFO],
                @request.env[Rack::REQUEST_METHOD],
                request: @request,
                context: self
              )

              break if found?
            end
          end

          handle(404, false) unless found?
        end
      end
    # TODO: make sure we can handle framework errors that occur outside of the request / response lifecycle
    rescue StandardError => error
      request.error = error

      puts error

      catch :halt do
        hook_around :error do
          handle(500, false) unless found?
        end
      end
    ensure
      return @response.finish
    end

    def load_app
      return unless config.app
      Loader.new.load_from_path(config.app.src)
    end

    protected

    # Interrupts the application and returns response immediately.
    #
    def halt
      throw :halt, response
    end

    def reject
      throw :reject
    end

    # Routes the request to different logic.
    #
    # TODO: change this to reroute(location, method: request.method)
    def reroute(location, method = nil)
      # TODO: a lot of the complexity in this object is due to rerouting
      # perhaps we can simplify things by creating a new request object
      # and providing access to the previous request via `parent`

      request.setup(router.path(location), method)

      hook_around :route do
        router.reroute(request)
      end
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
      puts "handle #{name_or_code}"
      # @handling = true

      # hook_around :route do
      #   # TODO: we need handlers at the router and app level
      #   # the ones in the router would handle errors originating from one of the contained routes
      #   # and the ones in the app would be the fallback for when nothing was matched, or no handlers were defined in the route
      #   router.handle(name_or_code, self, from_logic)
      # end
    end

    def found?
      @found == true
    end

    def path(name, **params)
      path_to(*name.to_s.split("_").map(&:to_sym), **params)
    end

    def path_to(*names, **params)
      first_name = names.first
      router.reject { |router_to_match|
        router_to_match.name.nil? || router_to_match.name != first_name
      }.each do |matched_router|
        if path = matched_router.path_to(*names[1..-1], **params)
          return path
        end
      end
    end
  end
end
