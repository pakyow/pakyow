# frozen_string_literal: true

require "irb"
require "rack"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"
require "pakyow/support/logging"

require "pakyow/environment/behavior/config"
require "pakyow/environment/behavior/initializers"
require "pakyow/environment/behavior/plugins"
require "pakyow/environment/behavior/request_parsing"
require "pakyow/environment/behavior/silencing"

require "pakyow/app"
require "pakyow/logger"

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
# Hooks can be defined for the following events: configure, setup, boot, and fork.
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
  unfreezable :logger, :app

  include Support::Hookable
  events :load, :configure, :setup, :boot, :fork, :shutdown

  include Support::Configurable

  include Environment::Behavior::Config
  include Environment::Behavior::Initializers
  include Environment::Behavior::Plugins
  include Environment::Behavior::RequestParsing
  include Environment::Behavior::Silencing

  # @api private
  SERVERS = %w(puma).freeze
  # @api private
  STOP_METHODS = %w(stop! stop).freeze
  # @api private
  STOP_SIGNALS = %w(INT TERM).freeze

  extend Support::ClassState
  class_state :apps,        default: []
  class_state :tasks,       default: []
  class_state :mounts,      default: {}
  class_state :frameworks,  default: {}
  class_state :builder,     default: Rack::Builder.new
  class_state :booted,      default: false, getter: false
  class_state :server,      default: nil, getter: false
  class_state :env,         default: nil, getter: false
  class_state :setup_error, default: nil

  class << self
    # Name of the environment
    #
    attr_reader :env

    # Port that the environment is running on
    #
    attr_reader :port

    # Host that the environment is running on
    #
    attr_reader :host

    # Name of the app server running in the environment
    #
    attr_reader :server

    # Logger instance for the environment
    #
    attr_reader :logger

    # The main Pakyow process.
    #
    attr_accessor :process

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
      mounts[at] = { app: app, block: block }
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

    # Prepares the Pakyow Environment for running.
    #
    # @param env [Symbol] the environment that Pakyow will be started in
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

        mounts.each do |path, mount|
          builder_local_environment = self

          builder.map path do
            run builder_local_environment.initialize_app_for_mount(mount, builder: self)
          end
        end
      end

      self
    rescue => error
      @setup_error = error
    end

    # Returns true if the environment has booted.
    #
    def booted?
      @booted == true
    end

    # Boots the Pakyow Environment without running it.
    #
    def boot
      ensure_setup_succeeded

      mounts.values.each do |mount|
        initialize_app_for_mount(mount)
      end

      booted
    end

    # Runs the Pakyow Environment.
    #
    # @param server [Symbol] name of the rack handler to use
    #
    # This method also accepts arbitrary options, which are passed directly to the handler.
    #
    def run(server: nil, **opts)
      ensure_setup_succeeded

      @server = server || config.server.name

      opts = if server_config_file_exists?
        {}
      else
        default_options_for_server(opts)
      end

      @host, @port = opts.values_at(:host, :port)

      if @mounts.any?
        handler(@server).run(to_app, **opts) do |app_server|
          deep_freeze if config.freeze_on_boot

          at_exit do
            stop(app_server)
          end

          STOP_SIGNALS.each do |signal|
            trap signal do
              stop(app_server)
            end
          end

          yield if block_given?
        end
      else
        fail "can't run because no apps are mounted"
      end
    rescue SignalException
      exit
    end

    # Tells Pakyow that the environment is being forked.
    #
    # When running the environment with a forking server (e.g. Passenger) call
    # this to tell Pakyow that the environment is being forked. Expects a block
    # to be passed. Any before :fork hooks will be called, then the block will
    # be yielded to, then any after :fork hooks will be called.
    #
    def fork
      forking
      yield
      forked
    end

    # When running the app with a forking server (e.g. Passenger), call this before
    # the process is forked. All defined "before fork" hooks will be called.
    #
    def forking
      call_hooks :before, :fork

      @apps.select { |app|
        app.respond_to?(:forking)
      }.each(&:forking)
    end

    # When running the app with a forking server (e.g. Passenger), call this after
    # the process is forked. All defined "after fork" hooks will be called.
    #
    def forked
      call_hooks :after, :fork

      @apps.select { |app|
        app.respond_to?(:forked)
      }.each(&:forked)

      booted
    end

    def register_framework(framework_name, framework_module)
      @frameworks[framework_name] = framework_module
    end

    def app(app_name, path: "/", without: [], only: nil, &block)
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
          mount(app, at: path)
        end
      end
    end

    def env?(name)
      env == name.to_sym
    end

    # @api private
    def to_app
      builder.to_app.tap do
        # Tasks should only be available before boot.
        #
        @tasks = []

        booted
      end
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
    def initialize_app_for_mount(mount, builder: @builder)
      app_instance = if mount[:app].ancestors.include?(Pakyow::App)
        mount[:app].new(env, builder: builder, &mount[:block])
      else
        mount[:app].new
      end

      @apps << app_instance
      app_instance
    end

    private

    def booted
      unless booted?
        # Protect against changing frozen state since workers will call `booted`
        # after booting and freezing the environment in the main process.
        #
        @booted = true
      end

      call_hooks(:after, :boot)
      @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
    rescue StandardError => error
      handle_boot_failure(error)
    end

    def use(middleware, *args)
      @builder.use(middleware, *args)
    end

    def init_global_logger
      logs = config.logger.destinations
      @logger = Logger.new(Logger::MultiLog.new(*logs))
      @logger.level = Logger.const_get(config.logger.level.to_s.upcase)
      @logger.formatter = config.logger.formatter.new
    end

    def handler(preferred)
      Rack::Handler.get(preferred) || Rack::Handler.pick(SERVERS)
    end

    def stop(server)
      call_hooks :before, :shutdown

      @apps.select { |app|
        app.respond_to?(:shutdown)
      }.each(&:shutdown)

      STOP_METHODS.each do |method|
        if server.respond_to?(method)
          return server.send(method)
        end
      end

      # exit ungracefully
      ::Process.exit!
    end

    def server_config_file_exists?
      File.exist?("./config/#{@server}.rb") || File.exist?("./config/#{@server}/#{@env}.rb")
    end

    def default_options_for_server(opts)
      if config.respond_to?(@server)
        opts = config.public_send(@server).to_h.deep_dup.merge(
          opts.reject { |_, v| v.nil? }
        )

        if @server == :puma
          opts[:Host] = opts[:host]
          opts[:Port] = opts[:port]
          opts[:Silent] = opts[:silent]
        end
      end

      opts
    end

    def ensure_setup_succeeded
      if @setup_error
        handle_boot_failure(@setup_error)
      end
    end

    def handle_boot_failure(error)
      @error = error

      Support::Logging.safe(level: Logger.const_get(config.logger.level.to_s.upcase), formatter: config.logger.formatter.new) do |logger|
        logger.error(error)
      end

      if config.exit_on_boot_failure
        exit
      end
    end
  end
end
