require_relative 'helpers/configuring'
require_relative 'helpers/running'

require_relative 'call_context'
require_relative 'helpers'
require_relative 'config'
require_relative 'loader'
require_relative 'router'

require "pakyow/support/hookable"

module Pakyow
  # The main app object.
  #
  # @api public
  class App
    include Support::Hookable
    
    known_events :init, :configure, :load, :reload, :fork

    extend Helpers::Configuring
    extend Helpers::Running

    class << self
      # Convenience method for accessing app configuration object.
      #
      # @api public
      def config
        Pakyow::Config
      end

      # Resets app state.
      #
      # @api private
      def reset
        instance_variables.each do |ivar|
          remove_instance_variable(ivar)
        end
      end
    end

    def initialize
      Pakyow.app = self

      @loader = Loader.new

      hook_around :init do
        load_app
      end
    end

    # @api private
    def call(env)
      CallContext.new(env).process.finish
    end

    # Reloads the app.
    #
    # @api private
    def reload
      hook_around :reload do
        load_app
      end
    end

    # When running the app with a forking server (e.g. Passenger) call this before
    # the process is forked. All defined "before fork" hooks will be called.
    #
    # @api private
    def forking
      call_hooks :before, :fork
    end

    # When running the app with a forking server (e.g. Passenger) call this after
    # the process is forked. All defined "after fork" hooks will be called.
    #
    # @api private
    def forked
      call_hooks :after, :fork
    end

    protected

    def load_app
      hook_around :load do
        @loader.load_from_path(Pakyow::Config.app.src_dir)
        load_routes unless Pakyow::Config.app.ignore_routes
      end
    end

    def load_routes
      Router.instance.reset

      self.class.routes.each_pair do |set_name, block|
        Router.instance.set(set_name, &block)
      end
    end
  end
end
