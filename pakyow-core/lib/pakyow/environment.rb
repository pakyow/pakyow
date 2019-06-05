# frozen_string_literal: true

require "async"

require "console"
require "console/split"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/logging"
require "pakyow/support/pipeline"
require "pakyow/support/inflector"

require "pakyow/environment/behavior/config"
require "pakyow/environment/behavior/initializers"
require "pakyow/environment/behavior/input_parsing"
require "pakyow/environment/behavior/plugins"
require "pakyow/environment/behavior/silencing"
require "pakyow/environment/behavior/timezone"
require "pakyow/environment/behavior/running"
require "pakyow/environment/behavior/watching"
require "pakyow/environment/behavior/restarting"

require "pakyow/environment/actions/dispatch"
require "pakyow/environment/actions/input_parser"
require "pakyow/environment/actions/logger"
require "pakyow/environment/actions/normalizer"

require "pakyow/app"

require "pakyow/logger/destination"
require "pakyow/logger/multiplexed"
require "pakyow/logger/thread_local"

# Pakyow environment for running one or more rack apps. Multiple apps can be
# mounted in the environment, each one handling requests at some path.
#
#   Pakyow.configure do
#     mount Pakyow::App, at: "/"
#   end
#
# = Configuration
#
# The environment can be configured
#
#   Pakyow.configure do
#     config.server.port = 2001
#   end
#
# It's possible to configure environments differently.
#
#   Pakyow.configure :development do
#     config.server.host = "pakyow.dev"
#   end
#
# @see Support::Configurable
#
# = Hooks
#
# Hooks can be defined for the following events:
#
#   - load
#   - configure
#   - setup
#   - boot
#   - shutdown
#   - run
#
# Here's how to log a message after boot:
#
#   Pakyow.after :boot do
#     logger.info "booted"
#   end
#
# @see Support::Hookable
#
# = Logging
#
# The environment contains a global general-purpose logger. It also provides
# a {RequestLogger} instance to each app for logging during a request.
#
# = Setup & Running
#
# The environment can be setup and then run.
#
#   Pakyow.setup(env: :development).run
#
module Pakyow
  using Support::DeepDup
  using Support::DeepFreeze
  using Support::Refinements::Array::Ensurable

  extend Support::DeepFreeze
  unfreezable :global_logger, :app

  include Support::Hookable
  events :load, :configure, :setup, :boot, :shutdown, :run

  include Support::Configurable

  include Environment::Behavior::Config
  include Environment::Behavior::Initializers
  include Environment::Behavior::InputParsing
  include Environment::Behavior::Plugins
  include Environment::Behavior::Silencing
  include Environment::Behavior::Timezone
  include Environment::Behavior::Running
  include Environment::Behavior::Watching
  include Environment::Behavior::Restarting

  include Support::Pipeline
  action Actions::Logger
  action Actions::Normalizer
  action Actions::InputParser
  action Actions::Dispatch

  extend Support::ClassState
  class_state :apps,        default: []
  class_state :tasks,       default: []
  class_state :mounts,      default: []
  class_state :frameworks,  default: {}
  class_state :booted,      default: false, getter: false
  class_state :server,      default: nil, getter: false
  class_state :env,         default: nil, getter: false
  class_state :setup_error, default: nil

  class << self
    # Name of the environment
    #
    attr_reader :env

    # Logger instance for the environment
    #
    attr_reader :logger

    # Global logger instance
    #
    attr_reader :global_logger

    # Any error encountered during the boot process
    #
    attr_reader :error

    # Mounts an app at a path.
    #
    # The app can be any rack endpoint, but must implement an
    # initializer like {App#initialize}.
    #
    # @param app the rack endpoint to mount
    # @param at [String] where the endpoint should be mounted
    #
    def mount(app, at:, &block)
      mounts << { app: app, block: block, path: at }
    end

    # Loads the Pakyow environment for the current project.
    #
    def load
      performing :load do
        if File.exist?(config.loader_path + ".rb")
          require config.loader_path
        else
          require "pakyow/integrations/bundler/setup"
          require "pakyow/integrations/bootsnap"

          require "pakyow/integrations/bundler/require"
          require "pakyow/integrations/dotenv"

          require config.environment_path

          load_apps
        end
      end
    end

    # Loads apps located in the current project.
    #
    def load_apps
      require "./config/application"
    end

    # Prepares the environment for booting.
    #
    # @param env [Symbol] the environment to prepare for
    #
    def setup(env: nil)
      @env = (env ||= config.default_env).to_sym

      load

      performing :configure do
        configure!(env)
        $LOAD_PATH.unshift(config.lib)
      end

      performing :setup do
        init_global_logger
      end

      self
    rescue => error
      begin
        # Try again to initialize the logger, since we may have failed before that point.
        #
        unless Pakyow.logger
          init_global_logger
        end
      rescue
      end

      @setup_error = error; self
    end

    # Returns true if the environment has booted.
    #
    def booted?
      @booted == true
    end

    # Boots the environment without running it.
    #
    def boot(unsafe: false)
      ensure_setup_succeeded

      performing :boot do
        # Tasks should only be available before boot.
        #
        @tasks = [] unless unsafe

        @apps = mounts.map { |mount|
          initialize_app_for_mount(mount)
        }

        @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
      end

      @booted = true
      @pipeline = Pakyow.__pipeline.callable(self)

      if config.freeze_on_boot
        deep_freeze unless unsafe
      end

      self
    rescue StandardError => error
      handle_boot_failure(error)
    end

    def register_framework(framework_name, framework_module)
      @frameworks[framework_name] = framework_module
    end

    def app(app_name, path: "/", without: [], only: nil, mount: true, &block)
      app_name = app_name.to_sym

      if booted?
        @apps.find { |app|
          app.config.name == app_name
        }
      else
        local_frameworks = (only || frameworks.keys) - Array.ensure(without)

        Pakyow::App.make(Support::ObjectName.namespace(app_name, "app")) {
          config.name = app_name
          include_frameworks(*local_frameworks)
        }.tap do |app|
          app.define(&block) if block_given?
          mount(app, at: path) if mount
        end
      end
    end

    def env?(name)
      env == name.to_sym
    end

    def call(input)
      config.connection_class.new(input).yield_self { |connection|
        Async(logger: connection.logger) {
          # Set the request logger as a thread-local variable for when there's no other way to access
          # it. This originated when looking for a way to log queries with the request logger. By
          # setting the request logger for the current connection as thread-local we can create a
          # connection pointing to `Pakyow.logger`, an instance of `Pakyow::Logger::ThreadLocal`. The
          # thread local logger decides at the time of logging which logger to use based on an
          # available context, falling back to `Pakyow.global_logger`. This gets us around needing to
          # configure a connection per request, altering Sequel's internals, and other oddities.
          #
          # Pakyow is designed so that the connection object and its logger should always be available
          # anywhere you need it. If it isn't, reconsider the design before using the thread local.
          #
          Thread.current[:pakyow_logger] = connection.logger

          catch :halt do
            @pipeline.call(connection)
          end
        }.wait
      }.finalize
    rescue StandardError => error
      Pakyow.logger.houston(error)

      Async::HTTP::Protocol::Response.new(
        nil, 500, nil, {},
        Async::HTTP::Body::Buffered.wrap(
          StringIO.new("500 Low-Level Server Error")
        )
      )
    end

    # @api private
    def load_tasks
      require "rake"
      require "pakyow/task"

      @tasks = config.tasks.paths.uniq.each_with_object([]) do |tasks_path, tasks|
        Dir.glob(File.join(File.expand_path(tasks_path), "**/*.rake")).each do |task_path|
          tasks.concat(Pakyow::Task::Loader.new(task_path).__tasks)
        end
      end
    end

    # @api private
    def initialize_app_for_mount(mount)
      if mount[:app].ancestors.include?(Pakyow::App)
        mount[:app].new(env, mount_path: mount[:path], &mount[:block])
      else
        mount[:app].new
      end
    end

    private

    def init_global_logger
      destinations = Logger::Multiplexed.new(
        *config.logger.destinations.map { |destination, io|
          io.sync = config.logger.sync
          Logger::Destination.new(destination, io)
        }
      )

      @global_logger = config.logger.formatter.new(destinations)

      @logger = Logger::ThreadLocal.new(
        Logger.new("pkyw", output: @global_logger, level: config.logger.level)
      )

      Console.logger = Logger.new("asnc", output: @global_logger, level: :warn)
    end

    def ensure_setup_succeeded
      if @setup_error
        handle_boot_failure(@setup_error)
      end
    end

    def handle_boot_failure(error)
      @error = error

      Support::Logging.safe do |logger|
        logger.houston(error)
      end

      if config.exit_on_boot_failure
        exit(false)
      end
    end
  end
end
