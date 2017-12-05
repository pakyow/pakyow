# frozen_string_literal: true

require "pakyow/support/configurable"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/recursive_require"
require "pakyow/support/deep_freeze"
require "pakyow/support/makeable"

require "pakyow/core/call"
require "pakyow/core/helpers"
require "pakyow/core/loader"
require "pakyow/core/paths"

require "forwardable"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
  #
  # For example:
  #
  #   Pakyow::App.define do
  #     # define shared state here
  #   end
  #
  #   class APIApp < Pakyow::App
  #     # define state here
  #   end
  #
  #   Pakyow.configure do
  #     mount Pakyow::App, at: "/"
  #     mount APIApp, at: "/api"
  #   end
  #
  # One or more routers can be registered to process incoming requests.
  #
  # For example:
  #
  #   Pakyow::App.router do
  #     default do
  #       logger.info "hello world"
  #     end
  #   end
  #
  # Each request is processed in an instance of {Controller}.
  #
  # = Application Configuration
  #
  # Application objects can be configured. For example:
  #
  #   Pakyow::App.configure do
  #     config.app.name = "my-app"
  #   end
  #
  # It's possible to configure for specific environments. For example, here's
  # how to override +app.name+ in the +development+ environment:
  #
  #   Pakyow::App.configure :development do
  #     config.app.name = "my-dev-app"
  #   end
  #
  # The +app+ config namespace can be extended with custom options. For example:
  #
  #   Pakyow::App.configure do
  #     config.app.foo = "bar"
  #   end
  #
  # == Configuration Options
  #
  # These config options are available:
  #
  # - +config.app.name+ defines the name of the application, used when a human
  #   readable unique identifier is necessary. Default is "pakyow".
  #
  # - +config.app.root+ defines the root directory of the application, relative
  #   to where the environment is started from. Default is +./+.
  #
  # - +config.app.src+ defines where the application code lives, relative to
  #   where the environment is started from. Default is +{app.root}/app/lib+.
  #
  # - +config.app.dsl+ determines whether or not objects creation will be exposed
  #   through the simpler dsl.
  #
  # - +config.routing.enabled+ determines whether or not routing is enabled for
  #   the application. Default is +true+, except when running in the
  #   +prototype+ environment.
  #
  # - +config.cookies.path+ sets the URL path that must exist in the requested
  #   resource before sending the Cookie header. Default is +/+.
  #
  # - +config.cookies.expiry+ sets when cookies should expire, specified in
  #   seconds. Default is +60 * 60 * 24 * 7+ seconds, or 7 days.
  #
  # - +config.session.enabled+ determines whether sessions are enabled for the
  #   application. Default is +true+.
  #
  # - +config.session.key+ defines the name of the key that holds the session
  #   object. Default is +{app.name}.session+.
  #
  # - +config.session.secret+ defines the value used to verify that the session
  #   has not been tampered with. Default is the value of the +SESSION_SECRET+
  #   environment variable.
  #
  # - +config.session.old_secret+ defines the old session secret, which is
  #   used to rotate session secrets in a graceful manner.
  #
  # - +config.session.expiry+ sets when sessions should expire, specified in
  #   seconds.
  #
  # - +config.session.path+ defines the path for the session cookie.
  #
  # - +config.session.domain+ defines the domain for the session cookie.
  #
  # - +config.session.options+ contains options passed to the session store.
  #
  # - +config.session.object+ defines the object used to store sessions. Default
  #   is +Rack::Session::Cookie+.
  #
  # - +config.protection.enabled+ determines whether or not to use
  #   +Rack::Protection+ for the applicaton. Default is +true+.
  #
  # See {Support::Configurable} for more information.
  #
  # = Application Hooks
  #
  # Hooks can be defined for these events:
  #
  # - initialize
  # - configure
  # - load
  # - freeze
  #
  # For example, here's how to write to the log after initialization:
  #
  #   Pakyow.after :initialize do
  #     logger.info "application initialized"
  #   end
  #
  # See {Support::Hookable} for more information.
  #
  class App
    class << self
      # Includes one or more frameworks into the app class.
      #
      def include_frameworks(*frameworks)
        frameworks.each do |framework|
          include_framework(framework)
        end

        self
      end

      # Includes a framework into the app class.
      #
      def include_framework(framework)
        Pakyow.frameworks[framework].new(self).boot
        (@loaded_frameworks ||= []) << framework
      end

      # Returns true if +framework+ is loaded.
      #
      def includes_framework?(framework)
        @loaded_frameworks.include?(framework)
      end

      # Registers a concern by name.
      #
      # @see concerns
      def concern(name)
        (concerns << name.to_s).uniq!
      end

      # Register an endpoint by name.
      #
      def endpoint(object)
        endpoints << object
      end

      # Registers a helper module to be loaded on defined endpoints.
      #
      def helper(helper_module)
        helpers << helper_module
      end

      # @api private
      def concerns
        @concerns ||= []
      end

      # @api private
      def endpoints
        @endpoints ||= []
      end

      # @api private
      def helpers
        @helpers ||= []
      end

      def inherited(subclass)
        super

        subclass.instance_variable_set(:@endpoints, endpoints.dup)
        subclass.instance_variable_set(:@concerns, concerns.dup)
        subclass.instance_variable_set(:@helpers, helpers.dup)
      end
    end

    include Support::Definable
    extend Support::Makeable

    include Support::Hookable
    known_events :initialize, :configure, :load, :freeze

    extend Forwardable

    # @!method use
    # Delegates to {builder}.
    def_delegators :builder, :use

    include Support::Configurable

    settings_for :app, extendable: true do
      setting :name, "pakyow"
      setting :root, File.dirname("")

      setting :src do
        File.join(config.app.root, "backend")
      end

      setting :dsl, true
    end

    settings_for :cookies do
      setting :path, "/"

      setting :expiry, 60 * 60 * 24 * 7
    end

    settings_for :protection do
      setting :enabled, true
    end

    settings_for :session do
      setting :enabled, true

      setting :key do
        "#{config.app.name}.session"
      end

      setting :secret do
        ENV["SESSION_SECRET"]
      end

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

        # set expiry if set
        if expiry = config.session.expiry
          opts[:expire_after] = expiry
        end

        # set optional options if available
        %i(domain path old_secret).each do |opt|
          if value = config.session.send(opt)
            opts[opt] = value
          end
        end

        opts
      end
    end

    # Loads and configures the session middleware.
    #
    after :configure do
      if config.session.enabled
        builder.use config.session.object, config.session.options
      end

      if config.protection.enabled
        require "rack-protection"
        builder.use(Rack::Protection, except: config.session.enabled ? [] : %i[session_hijacking remote_token])
      end
    end

    before :freeze do
      load_paths
    end

    # The environment the app is defined in.
    #
    attr_reader :environment

    # The rack builder.
    #
    attr_reader :builder

    # Path lookup for endpoints.
    #
    attr_reader :paths

    extend Support::DeepFreeze
    unfreezable :builder

    def initialize(environment, builder: nil, &block)
      @paths = Paths.new
      @environment = environment
      @builder = builder

      @endpoints = self.class.endpoints.map { |endpoint|
        self.class.helpers.each do |helper_module|
          endpoint.class_eval do
            include helper_module
          end
        end

        endpoint
      }

      hook_around :initialize do
        hook_around :configure do
          use_config(environment)
        end

        hook_around :load do
          load_app
        end
      end

      # Call the Pakyow::Definable initializer.
      #
      # This ensures that any state registered in the passed block
      # has the proper priority against instance and global state.
      defined!(&block)
    end

    RESPOND_MISSING = [[], 404, {}].freeze
    RESPOND_ERRORED = [[], 500, {}].freeze

    def call(env)
      call = Call.new(self, Request.new(env), Response.new)

      response = catch(:halt) {
        @endpoints.each do |endpoint|
          endpoint.call(call)
        end

        # If no endpoint has halted or marked the call as processed, assume
        # that the call was unhandled and return a 404 response.
        unless call.processed?
          handle_missing(call)
        end
      } || call.response

      call.request.set_cookies(response, config.cookies); response
    rescue StandardError => error
      env[Rack::RACK_LOGGER].houston(error)

      catch(:halt) {
        handle_failure(call, error)
      }
    end

    def freeze
      hook_around :freeze do
        super
      end
    end

    protected

    def handle_missing(call)
      @endpoints.each do |endpoint|
        endpoint.handle_missing(call)
      end

      unless call.handled_missing?
        throw :halt, Response.new(*RESPOND_MISSING)
      end
    end

    def handle_failure(call, error)
      @endpoints.each do |endpoint|
        endpoint.handle_failure(call, error)
      end

      unless call.handled_failure?
        throw :halt, Response.new(*RESPOND_ERRORED)
      end
    end

    def load_app
      $LOAD_PATH.unshift(File.join(config.app.src, "lib"))

      self.class.concerns.each do |concern|
        load_app_concern(File.join(config.app.src, concern), concern)
      end
    end

    def load_app_concern(state_path, state_type, load_target = self.class)
      Dir.glob(File.join(state_path, "*.rb")) do |path|
        if config.app.dsl
          Loader.new(load_target, Support::ClassNamespace.new(config.app.name, state_type), path).call
        else
          require path
        end
      end

      Dir.glob(File.join(state_path, "*")).select { |path| File.directory?(path) }.each do |directory|
        load_app_concern(directory, state_type, load_target)
      end
    end

    def load_paths
      state.each_with_object(@paths) { |(_, state_object), paths|
        state_object.instances.each do |state_instance|
          paths << state_instance if state_instance.respond_to?(:path_to)
        end
      }
    end
  end
end
