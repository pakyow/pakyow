# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/configurable"
require "pakyow/support/deep_freeze"
require "pakyow/support/definable"
require "pakyow/support/hookable"
require "pakyow/support/inspectable"
require "pakyow/support/makeable"
require "pakyow/support/path_version"
require "pakyow/support/pipeline"

require "pakyow/application/connection"
require "pakyow/application/behavior/sessions"
require "pakyow/application/behavior/endpoints"
require "pakyow/application/behavior/frameworks"
require "pakyow/application/behavior/aspects"
require "pakyow/application/behavior/helpers"
require "pakyow/application/behavior/rescuing"
require "pakyow/application/behavior/restarting"
require "pakyow/application/behavior/initializers"
require "pakyow/application/behavior/plugins"
require "pakyow/application/behavior/operations"

require "pakyow/connection"

module Pakyow
  # Pakyow's main application object. Can be defined directly or subclassed to
  # create multiple application objects, each containing its own state. These
  # applications can then be mounted as an endpoint within the environment.
  #
  #   Pakyow::Application.define do
  #     # state shared between all apps goes here
  #   end
  #
  #   class API < Pakyow::Application
  #     # state for this app goes here
  #   end
  #
  #   Pakyow.configure do
  #     mount API, at: "/api"
  #   end
  #
  # = Pipeline
  #
  # Requests are received by {Application#call}, creating a {Connection} object that
  # provides an interface to the underlying request state. The connection is
  # pushed through a pipeline. Each pipeline action can modify the connection
  # and then either 1) allow the connection to hit the next action 2) halt
  # pipeline execution completely.
  #
  # Once the connection exits the pipeline a response is returned. If an action
  # halted, the connection is finalized and returned, otherwise app assumes
  # that the connection was unhandled and returns a canned 404 response.
  #
  # Application also catches any unhandled errors that occur in the pipeline by simply
  # logging the error and returning a canned 500 response.
  #
  # @see Support::Pipeline
  #
  # = Configuration
  #
  # Application objects can be configured.
  #
  #   Pakyow::Application.configure do
  #     config.name = "my-app"
  #   end
  #
  # It's possible to configure for certain environments.
  #
  #   Pakyow::Application.configure :development do
  #     config.name = "my-dev-app"
  #   end
  #
  # The +app+ config namespace can be extended with your own custom options.
  #
  #   Pakyow::Application.configure do
  #     config.foo = "bar"
  #   end
  #
  # @see Support::Configurable
  #
  # = Hooks
  #
  # Hooks can be defined for the following events:
  #
  #   - initialize
  #   - configure
  #   - load
  #   - finalize
  #   - boot
  #   - rescue
  #   - shutdown
  #
  # Here's how to log a message after initialize:
  #
  #   Pakyow::Application.after "initialize" do
  #     logger.info "initialized #{self}"
  #   end
  #
  # @see Support::Hookable
  #
  class Application
    # Environment the app is booted in, e.g. +:development+.
    #
    attr_reader :environment

    # Application mount path.
    #
    attr_reader :mount_path

    include Support::Inspectable
    inspectable :@environment

    include Support::Hookable
    events :setup, :initialize, :configure, :load, :finalize, :boot, :rescue, :shutdown

    extend Support::ClassState
    class_state :__setup, default: false, reader: false

    include Support::Configurable

    setting :name, :pakyow
    setting :version

    setting :root do
      Pakyow.config.root
    end

    setting :src do
      File.join(config.root, "backend")
    end

    setting :lib do
      File.join(config.src, "lib")
    end

    configurable :tasks do
      setting :prelaunch, []
    end

    configurable :commands do
      setting :prelaunch, []
    end

    include Support::Definable
    include Support::Makeable
    include Support::Pipeline

    include Behavior::Sessions
    include Behavior::Endpoints
    include Behavior::Frameworks
    include Behavior::Aspects
    include Behavior::Helpers
    include Behavior::Rescuing
    include Behavior::Restarting
    include Behavior::Initializers
    include Behavior::Plugins
    include Behavior::Operations

    # Isolate the connection before making the app so that other before make hooks and the make
    # block itself has access to the isolated connection class. In practice, this design detail
    # allows frameworks to access and extend the isolated connection class.
    #
    on "make", priority: :high do
      isolate Connection
    end

    class << self
      def setup(environment: Pakyow.env, &block)
        if block_given?
          class_eval(&block)
        end

        unless setup?
          performing :setup do
            performing :configure do
              configure!(environment)
            end

            performing :load do
              $LOAD_PATH.unshift(config.lib)
            end

            config.version = Support::PathVersion.build(config.src)
          end

          @__setup = true
        end

        self
      rescue ScriptError, StandardError => error
        rescue!(error)
      end

      # Returns true if the application has been setup.
      #
      def setup?
        @__setup == true
      end
    end

    def initialize(environment = Pakyow.env, mount_path: "/")
      @environment, @mount_path = environment, mount_path

      # Prevent full initialization if rescued, probably because of an error during setup.
      #
      unless rescued?
        performing :initialize do
          # Empty, but still need to perform initialize.
        end
      end
    end

    # Called by the environment after it boots the app.
    #
    def booted
      unless rescued?
        call_hooks :after, :boot
      end
    rescue ScriptError, StandardError => error
      rescue!(error)
    end

    # Calls the app pipeline with a connection created from the rack env.
    #
    def call(connection)
      app_connection = isolated(:Connection).new(self, connection)
      super(app_connection)
    rescue => error
      if app_connection && respond_to?(:controller_for_connection) && controller = controller_for_connection(app_connection)
        controller.handle_error(error)
      else
        raise error
      end
    end

    def shutdown
      performing :shutdown do; end
    end

    def _dump(_)
      Marshal.dump(
        {
          name: config.name
        }
      )
    end

    def self._load(state)
      Pakyow.app(Marshal.load(state)[:name])
    end

    # @api private
    def top
      self
    end

    # @api private
    def perform(app_connection)
      @__pipeline.call(app_connection)
    end

    class << self
      private def isolable_context
        object_name && object_name.namespace.parts.any? ? Kernel.const_get(object_name.namespace.constant) : self
      end
    end
  end
end
