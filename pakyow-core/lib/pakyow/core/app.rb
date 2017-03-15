require "pakyow/support/configurable"
require "pakyow/support/defineable"
require "pakyow/support/hookable"
require "pakyow/support/recursive_require"

require "pakyow/core/helpers"
require "pakyow/core/router"

require "forwardable"

require "rack-protection"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
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
  #
  # For example, here's how to write to the log after initialization:
  #
  #   Pakyow.after :initialize do
  #     logger.info "application initialized"
  #   end
  #
  # See {Support::Hookable} for more information.
  #
  # @api public
  class App
    include Support::Defineable

    # @!scope class
    # @!method router(name_or_path = nil, path_or_name = nil, before: [], after: [], around: [], &block)
    #   Defines a router for the application. For example:
    #
    #     Pakyow::App.router do
    #     end
    #
    #   The router can be defined with a name, which creates a group
    #   (see {Router#group}). For example:
    #
    #     Pakyow::App.router :post do
    #     end
    #
    #   The router can also be created with both a name and path, which creates
    #   a namespace (see {Router#namespace}). For example:
    #
    #     Pakyow::App.router :post, "/posts" do
    #     end
    #
    #   It's possible to create an anonymous namespace by passing just a path.
    #   For example:
    #
    #     Pakyow::App.router "/posts" do
    #     end
    #
    #   Routes defined in the above router would be prefixed, but would be
    #   unavailable in path building (see {path} and {path_to}).
    #
    #   @param name_or_path [Symbol, String] the name or path for the router
    #   @param path_or_name [String, Symbol] the path or name for the router
    #   @param before [Array<Symbol, Proc>] an array of before hooks
    #   @param after [Array<Symbol, Proc>] an array of after hooks
    #   @param around [Array<Symbol, Proc>] an array of around hooks
    #
    #   @api public
    stateful :router, Router

    include Support::Hookable
    known_events :initialize, :configure, :load

    include Support::Configurable

    extend Forwardable

    # @!method use
    # Delegates to {builder}.
    def_delegators :builder, :use

    settings_for :app, extendable: true do
      setting :name, "pakyow"
      setting :root, File.dirname("")

      setting :src do
        File.join(config.app.root, "app", "lib")
      end
    end

    settings_for :routing do
      setting :enabled, true

      defaults :prototype do
        setting :enabled, false
      end
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
          value = config.session.send(opt)
          opts[opt] = value if value
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
        builder.use(Rack::Protection, except: config.session.enabled ? [] : [:session_hijacking, :remote_token])
      end
    end

    # The environment the app is defined in.
    #
    # @api public
    attr_reader :environment

    # The rack builder.
    #
    # @api public
    attr_reader :builder

    class << self
      # Defines a RESTful resource. For example:
      #
      #   Pakyow::App.resource :post, "/posts" do
      #     list do
      #     end
      #
      #     create do
      #     end
      #
      #     # etc
      #   end
      #
      # @see Routing::Extension::Resource
      #
      # @api public
      def resource(name, path, &block)
        raise ArgumentError, "Expected a block" unless block_given?

        # TODO: move this to a define_resource hook
        RESOURCE_ACTIONS.each do |plugin, action|
          action.call(self, name, path, block)
        end
      end

      # @api private
      RESOURCE_ACTIONS = {
        core: Proc.new do |app, name, path, block|
          app.router do
            resource name, path, &block
          end
        end
      }
    end

    # @api private
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
      #
      # This ensures that any state registered in the passed block
      # has the proper priority against instance and global state.
      super(&block)
    end

    # @api private
    def call(env)
      Controller.process(env, self)
    end

    protected

    using Support::RecursiveRequire

    def load_app
      require_recursive(config.app.src)
    end
  end
end
