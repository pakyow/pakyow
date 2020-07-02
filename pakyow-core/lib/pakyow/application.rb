# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/configurable"
require "pakyow/support/deep_freeze"
require "pakyow/support/definable"
require "pakyow/support/handleable"
require "pakyow/support/hookable"
require "pakyow/support/inspectable"
require "pakyow/support/makeable"
require "pakyow/support/path_version"
require "pakyow/support/pipeline"

require_relative "application/connection"
require_relative "application/behavior/sessions"
require_relative "application/behavior/endpoints"
require_relative "application/behavior/frameworks"
require_relative "application/behavior/aspects"
require_relative "application/behavior/helpers"
require_relative "application/behavior/rescuing"
require_relative "application/behavior/initializers"
require_relative "application/behavior/plugins"
require_relative "application/behavior/operations"
require_relative "application/behavior/multiapp"

require_relative "application/actions/missing"

require_relative "handleable/actions/handle"
require_relative "handleable/behavior/statuses"
require_relative "handleable/behavior/defaults/not_found"
require_relative "handleable/behavior/defaults/server_error"

require_relative "connection"
require_relative "errors"

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
    events :setup, :initialize, :configure, :load, :finalize, :boot, :shutdown

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

      deprecate :prelaunch
    end

    include Support::Definable
    include Support::Handleable
    include Support::Makeable

    include Support::Pipeline
    action :handle, Handleable::Actions::Handle
    action :missing, Actions::Missing

    include Behavior::Sessions
    include Behavior::Endpoints
    include Behavior::Frameworks
    include Behavior::Aspects
    include Behavior::Helpers
    include Behavior::Rescuing
    include Behavior::Initializers
    include Behavior::Plugins
    include Behavior::Operations
    include Behavior::Multiapp

    include Handleable::Behavior::Statuses

    include Handleable::Behavior::Defaults::NotFound
    include Handleable::Behavior::Defaults::ServerError

    # `Pakyow::Application` is frozen at runtime which precludes defining handlers in context of an
    # action or similar. Undefining the method results in a more user-friendly undefined method
    # error instead of a frozen error.
    #
    undef handle

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

        unless setup? || rescued?
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
        raise ApplicationError.build(error, context: self)
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
    rescue ScriptError, StandardError => error
      raise ApplicationError.build(error, context: self)
    end

    # Called by the environment after it boots the app.
    #
    def booted
      unless rescued?
        call_hooks :after, :boot
      end
    rescue ScriptError, StandardError => error
      raise ApplicationError.build(error, context: self)
    end

    # Returns true if the application accepts the connection.
    #
    def accept?(connection)
      connection.path.start_with?(mount_path)
    end

    # Calls the app pipeline with a connection created from the rack env.
    #
    def call(connection)
      super(isolated(:Connection).new(self, connection))
    end

    # Triggers `event`, passing any arguments to triggered handlers.
    #
    # Calls application handlers, then propagates the event to the environment.
    #
    def trigger(event, *args, **kwargs, &block)
      super do
        Pakyow.trigger(event, *args, **kwargs, &block)
      end
    end

    def shutdown
      unless rescued?
        performing :shutdown do; end
      end
    rescue ScriptError, StandardError => error
      raise ApplicationError.build(error, context: self)
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
      @__pipeline.call(self, app_connection)
    end

    class << self
      private def isolable_context
        object_name && object_name.namespace.parts.any? ? Kernel.const_get(object_name.namespace.constant) : self
      end
    end
  end
end
