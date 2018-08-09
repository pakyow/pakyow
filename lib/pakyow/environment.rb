# frozen_string_literal: true

require "irb"
require "rack"
require "logger"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"

require "pakyow/environment/behavior/config"

require "pakyow/logger"
require "pakyow/middleware"

require "pakyow/app"

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
# a {Logger::RequestLogger} instance to each app for logging during a request.
#
# = Middleware
#
# The environment contains a default middleware stack:
#
# - Rack::ContentType, "text/html"
# - Rack::ContentLength
# - Rack::Head
# - Rack::MethodOverride
# - {Middleware::JSONBody}
# - {Middleware::Normalizer}
# - {Middleware::Logger}
#
# Each endpoint can add its own middleware through its builder.
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
  known_events :configure, :setup, :boot, :fork

  include Support::Configurable

  include Behavior::Config

  # Loads the default middleware stack.
  #
  before :setup do
    use Rack::ContentType, "text/html"
    use Rack::ContentLength
    use Rack::Head
    use Rack::MethodOverride
    use Middleware::JSONBody
    use Middleware::Normalizer
    use Middleware::Logger
  end

  # @api private
  SERVERS = %w(puma).freeze
  # @api private
  STOP_METHODS = %w(stop! stop).freeze
  # @api private
  STOP_SIGNALS = %w(INT TERM).freeze

  extend Support::ClassState
  class_state :apps,       default: []
  class_state :tasks,      default: []
  class_state :mounts,     default: {}
  class_state :frameworks, default: {}
  class_state :builder,    default: Rack::Builder.new
  class_state :booted,     default: false

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

    # Mounts an app at a path.
    #
    # The app can be any rack endpoint, but must implement an
    # initializer like {App#initialize}.
    #
    # @param app the rack endpoint to mount
    # @param at [String] where the endpoint should be mounted
    #
    def mount(app, at: nil, &block)
      raise ArgumentError, "Mount path is required" if at.nil?
      mounts[at] = { app: app, block: block }
    end

    # Prepares the Pakow Environment for running.
    #
    # @param env [Symbol] the environment that Pakyow will be started in
    #
    def setup(env: nil)
      @env = (env ||= config.default_env).to_sym

      performing :configure do
        configure!(env)
      end

      performing :setup do
        init_global_logger

        mounts.each do |path, mount|
          builder_local_apps = apps
          builder_local_environment = self

          builder.map path do
            app_instance = builder_local_environment.initialize_app_for_mount(mount, builder: self)
            builder_local_apps << app_instance
            run app_instance
          end
        end
      end

      self
    end

    def to_app
      builder.to_app.tap do
        # Tasks should only be available before boot.
        #
        @tasks = []

        booted
      end
    end

    # Returns true if the environment has booted.
    #
    def booted?
      @booted == true
    end

    def booted
      @booted = true unless booted?
      call_hooks(:after, :boot)
      @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
    rescue StandardError => error
      logger.error "Pakyow failed to boot: #{error}"
      logger.error error.backtrace
      exit
    end

    # Starts the Pakyow Environment.
    #
    # @param server [Symbol] name of the rack handler to use
    #
    # This method also accepts arbitrary options, which are passed directly to the handler.
    #
    def run(server: nil, **opts)
      @server = server || config.server.name

      opts = if server_config_file_exists?
        {}
      else
        default_options_for_server(opts)
      end

      @host, @port = opts.values_at(:host, :port)

      handler(@server).run(to_app, **opts) do |app_server|
        deep_freeze if config.freeze_on_boot

        at_exit do
          stop(app_server)
        end

        STOP_SIGNALS.each do |signal|
          trap(signal) {
            stop(app_server)
          }
        end

        yield if block_given?
      end
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
      local_frameworks = (only || frameworks.keys) - Array.ensure(without)

      app = Pakyow::App.make(Support::ClassName.namespace(app_name, "app")) {
        config.name = app_name
        include_frameworks(*local_frameworks)
      }

      app.define(&block) if block_given?
      mount(app, at: path)
      app
    end

    def find_app(name)
      name = name.to_sym

      if booted?
        apps.find { |app|
          app.config.name == name
        }
      else
        mount = mounts.values.find { |mount|
          mount[:app].config.name == name
        }

        if mount
          initialize_app_for_mount(mount)
        else
          nil
        end
      end
    end

    def env?(name)
      env == name.to_sym
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
      if mount[:app].ancestors.include?(Pakyow::App)
        mount[:app].new(env, builder: builder, &mount[:block])
      else
        mount[:app].new
      end
    end

    protected

    def use(middleware, *args)
      @builder.use(middleware, *args)
    end

    def init_global_logger
      logs = config.logger.destinations
      @logger = ::Logger.new(logs.count > 1 ? Logger::MultiLog.new(*logs) : logs.first)
      @logger.level = ::Logger.const_get(config.logger.level.to_s.upcase)
      @logger.formatter = config.logger.formatter.new
    end

    def handler(preferred)
      Rack::Handler.get(preferred) || Rack::Handler.pick(SERVERS)
    end

    def stop(server)
      STOP_METHODS.each do |method|
        return server.send(method) if server.respond_to?(method)
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
  end
end
