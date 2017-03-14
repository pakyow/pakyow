require "pakyow/support/configurable"
require "pakyow/support/defineable"
require "pakyow/support/hookable"
require "pakyow/support/recursive_require"

require "pakyow/core/helpers"
require "pakyow/core/router"

require "forwardable"

require "rack-protection"

module Pakyow
  # Pakyow's main app object. Can be defined directly or subclassed to create
  # multiple apps, each containing its own state. Each app can be defined and
  # mounted as an endpoint within the environment.
  #
  # @example Defining and mounting an app:
  #   Pakyow::App.define do
  #     # define state here
  #   end
  #
  #   Pakyow.configure do
  #     mount Pakyow::App, at: "/"
  #   end
  #
  # @example Creating a subclass:
  #   class SuperDuperApp < Pakyow::App
  #     # define app state here
  #   end
  #
  # Routers can be registered to process incoming requests.
  #
  # @example Defining a router:
  #   Pakyow::App.router do
  #     default do
  #       logger.info "hello world"
  #     end
  #   end
  #
  # Each request is processed in an instance of {Controller}.
  #
  # The following config settings are available to the app:
  #
  # - *app.name*: the name of the app  
  #   _default_: pakyow
  # - *app.root*: the root app directory  
  #   _default_: ./
  # - *app.src*: the app source location  
  #   _default_: ./app/lib
  #
  # - *router.enabled*: whether or not the router is enabled  
  #   _default_: true, false (prototype)
  #
  # - *cookies.path*: the cookies path  
  #   _default_: /
  # - *cookies.expiry*: when cookies should expire  
  #   _default_: 7 days from now
  #
  # - *session.enabled*: whether or not the app should use sessions  
  #   _default_: true
  # - *session.key*: the key to store the session under  
  #   _default_: {app.name}.session
  # - *session.secret*: the session secret  
  #   _default_: ENV["SESSION_SECRET"]
  # - *session.object*: the session class  
  #   _default_: Rack::Session::Cookie
  # - *session.old_secret*: the old session secret (set when rotating keys)
  # - *session.expiry*: when to expire the session
  # - *session.path*: the path for the session cookie
  # - *session.domain*: the domain for the session cookie
  # - *session.options*: options passed to {session.object}
  #
  # Configuration support is added via {Support::Configurable}.
  #
  # @example Configure the app:
  #   Pakyow::App.configure do
  #     config.app.name = "my-app"
  #   end
  #
  # @example Configure the app for a specific environment:
  #   Pakyow::App.configure :development do
  #     config.app.name = "my-app"
  #   end
  #
  # The `app` config namespace can be extended with your own options.
  #
  # @example Creating a config option:
  #   Pakyow::App.configure do
  #     config.app.foo = "bar"
  #   end
  #
  # Hooks are available to extend the app with custom behavior:
  #
  # - initialize
  # - configure
  # - load
  #
  # @example Run code after the app is initialized:
  #   Pakyow.after :initialize do
  #     # do something here
  #   end
  #
  # Hook support is added via {Support::Hookable}.
  #
  # @api public
  class App
    include Support::Defineable
    stateful :router, Router

    include Support::Hookable
    known_events :initialize, :configure, :load

    include Support::Configurable
    
    extend Forwardable
    def_delegators :@builder, :use

    settings_for :app, extendable: true do
      setting :name, "pakyow"
      setting :root, File.dirname("")

      setting :src do
        File.join(config.app.root, "app", "lib")
      end
    end

    settings_for :router do
      setting :enabled, true

      defaults :prototype do
        setting :enabled, false
      end
    end

    settings_for :cookies do
      setting :path, "/"

      setting :expiry do
        Time.now + 60 * 60 * 24 * 7
      end
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

        # set optional options if available
        %i(domain path expire_after old_secret).each do |opt|
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
        builder.use Rack::Protection, without_session: config.session.enabled
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
      # Defines a resource (see {Routing::Extension::Restful}).
      #
      # @example
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
