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
require "pakyow/support/pipeline"
require "pakyow/support/inflector"
require "pakyow/support/deprecatable"

require "pakyow/config"
require "pakyow/behavior/deprecations"
require "pakyow/behavior/initializers"
require "pakyow/behavior/input_parsing"
require "pakyow/behavior/plugins"
require "pakyow/behavior/silencing"
require "pakyow/behavior/timezone"
require "pakyow/behavior/running"
require "pakyow/behavior/watching"
require "pakyow/behavior/restarting"
require "pakyow/behavior/verifier"

require "pakyow/actions/dispatch"
require "pakyow/actions/input_parser"
require "pakyow/actions/logger"
require "pakyow/actions/normalizer"
require "pakyow/actions/restart"

require "pakyow/application"

require "pakyow/logger"
require "pakyow/logger/destination"
require "pakyow/logger/multiplexed"
require "pakyow/logger/thread_local"

# Pakyow environment for running one or more rack apps. Multiple apps can be
# mounted in the environment, each one handling requests at some path.
#
#   Pakyow.configure do
#     mount Pakyow::Application, at: "/"
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
#   Pakyow.after "boot" do
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

  include Support::Hookable
  events :load, :configure, :setup, :boot, :shutdown, :run

  include Support::Configurable

  include Config
  include Behavior::Initializers
  include Behavior::InputParsing
  include Behavior::Plugins
  include Behavior::Silencing
  include Behavior::Timezone
  include Behavior::Running
  include Behavior::Watching
  include Behavior::Restarting
  include Behavior::Verifier

  include Support::Pipeline
  action :log, Actions::Logger
  action :normalize, Actions::Normalizer
  action :parse, Actions::InputParser
  action :dispatch, Actions::Dispatch

  before :configure do
    if env?(:development) || env?(:prototype)
      action :restart, Actions::Restart, before: :dispatch
    end
  end

  extend Support::ClassState
  class_state :apps,        default: []
  class_state :tasks,       default: []
  class_state :mounts,      default: []
  class_state :frameworks,  default: {}
  class_state :booted,      default: false, reader: false
  class_state :server,      default: nil, reader: false
  class_state :env,         default: nil, reader: false
  class_state :setup_error, default: nil

  class << self
    extend Support::Deprecatable

    # Name of the environment
    #
    attr_reader :env

    # Any error encountered during the boot process
    #
    attr_reader :error

    # Global log output.
    #
    # Builds and returns a default global output that's replaced in `setup`.
    #
    def output
      unless defined?(@output)
        require "pakyow/logger/formatters/human"
        @output = Logger::Formatters::Human.new(
          Logger::Destination.new(:stdout, $stdout)
        )
      end

      @output
    end

    # @deprecated Use {output} instead.
    #
    def global_logger
      output
    end
    deprecate :global_logger, solution: "use `output'"

    # Logger instance for the environment.
    #
    # Builds and returns a default logger that's replaced in `setup`.
    #
    def logger
      @logger ||= Logger::ThreadLocal.new(Logger.new("dflt", output: output, level: :all), key: :pakyow_logger)
    end

    # Mounts an app at a path.
    #
    # The app can be any rack endpoint, but must implement an
    # initializer like {Application#initialize}.
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
      require File.join(config.root, "config/application")
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
        destinations = Logger::Multiplexed.new(
          *config.logger.destinations.map { |destination, io|
            io.sync = config.logger.sync
            Logger::Destination.new(destination, io)
          }
        )

        @output = config.logger.formatter.new(destinations)

        # Replace the default logger with a configured logger. We don't overwrite `@logger` here so
        # that objects that hold a reference to the thread local logger before setup still point to
        # the right object and log to the appropriate logger after setup.
        #
        logger.replace(Logger.new("pkyw", output: @output, level: config.logger.level))

        Console.logger = Logger.new("asnc", output: @output, level: :warn)
      end

      self
    rescue => error
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

        # Mount each app.
        #
        @apps = mounts.map { |mount|
          initialize_app_for_mount(mount)
        }

        # Create the callable pipeline.
        #
        @pipeline = Pakyow.__pipeline.callable(self)

        # Set the environment as booted ahead of telling each app that it is booted. This allows an
        # app's after boot hook to access the booted app through `Pakyow.app`.
        #
        @booted = true

        # Now tell each app that it has been booted.
        #
        @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
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

        Pakyow::Application.make(Support::ObjectName.build(app_name, "application")) {
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
        connection.async {
          catch :halt do
            @pipeline.call(connection)
          end
        }.wait
      }.finalize
    rescue StandardError => error
      Pakyow.logger.houston(error)

      Async::HTTP::Protocol::Response.new(
        nil, 500, {}, Async::HTTP::Body::Buffered.wrap(
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
      if mount[:app].ancestors.include?(Pakyow::Application)
        mount[:app].new(env, mount_path: mount[:path], &mount[:block])
      else
        mount[:app].new
      end
    end

    private

    def ensure_setup_succeeded
      if @setup_error
        handle_boot_failure(@setup_error)
      end
    end

    def handle_boot_failure(error)
      @error = error

      logger.houston(error)

      if config.exit_on_boot_failure
        exit(false)
      end
    end
  end

  include Behavior::Deprecations
end
