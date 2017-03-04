require "pakyow/support/configurable"
require "pakyow/support/defineable"
require "pakyow/support/hookable"
require "pakyow/support/recursive_require"

require "pakyow/core/helpers"
require "pakyow/core/router"

module Pakyow
  # TODO: better docs
  #
  # The main app object.
  #
  # Can be defined once, mounted multiple times.
  #
  # @api public
  class App
    include Support::Defineable
    stateful :router, Router

    include Support::Hookable
    known_events :initialize, :configure, :load

    include Support::Configurable

    using Pakyow::Support::RecursiveRequire

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
      Controller.process(env, self)
    end

    protected

    def load_app
      require_recursive(config.app.src)
    end
  end
end
