# frozen_string_literal: true

require "irb"
require "rack"
require "logger"

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/hookable"
require "pakyow/support/configurable"
require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"

require "pakyow/logger"
require "pakyow/middleware"

require "pakyow/app"

# An environment for running one or more rack apps.
#
# Multiple apps can be mounted within the environment, each one handling
# requests at some path. The environment doesn't care if the endpoints are
# Pakyow apps; any Rack endpoint is fine. But the environment does make
# some assumptions about how the endpoint will be initialized (see {App#initialize}).
#
# @example Mounting an app:
#   Pakyow.configure do
#     mount Pakyow::App, at: "/"
#   end
#
# == Configuration Options
#
# These config options are available:
#
# - +default_env+ defines the named environment to start when one is not
#   explicitly provided. Default is +:development+.
#
# - +server.name+ defines the application server to use by default.
#   Default is +:puma+.
# - +server.host+ defines the host that the environment runs on.
#   Default is "localhost".
# - +server.port+ defines the port that the environment runs on.
#   Default is +3000+.
#
# - +logger.enabled+ defines whether or not logging is enabled.
#   Default is +true+.
# - +logger.level+ defines what level to log at. Default is +:debug+, or
#   +:info+ in the +production+ environment.
# - +logger.formatter+ defines the formatter to use when logging. Default is
#   {Logger::DevFormatter}, or {Logger::LogfmtFormatter} in production.
# - +logger.destinations+ defines where logs are output to. Default is
#   +$stdout+ (when +logger.enabled+), or +/dev/null+ in the +test+
#   environment or when logger is disabled).
#
# - +normalizer.strict_path+ defines whether or not request paths are
#   normalized. Default is +true+.
# - +normalizer.strict_www+ defines whether or not the www subdomain are
#   normalized. Default is +false+.
# - +normalizer.require_www+ defines whether or not to require www in the
#   hostname. Default is +true+.
#
# - +tasks.paths+ defines paths where rake tasks are located. Default is +["./tasks"]+.
#
# Configuration support is added via {Support::Configurable}.
#
# @example Configure the environment:
#   Pakyow.configure do
#     config.server.port = 2001
#   end
#
# @example Configure for a specific environment:
#   Pakyow.configure :development do
#     config.server.host = "pakyow.dev"
#   end
#
# Hooks are available to extend the environment with custom behavior:
#
# - configure
# - setup
# - fork
#
# @example Run code after the environment is setup:
#   Pakyow.after :setup do
#     # do something here
#   end
#
# Hook support is added via {Support::Hookable}.
#
# The environment contains a global general-purpose logger. It also provides
# a {Logger::RequestLogger} instance to each app for logging additional
# metadata about each request.
#
# The environment is started with a default middleware stack:
#
# - Rack::ContentType, "text/html;charset=utf-8"
# - Rack::ContentLength
# - Rack::Head
# - Rack::MethodOverride
# - {Middleware::JSONBody}
# - {Middleware::ReqPathNormalizer}
# - {Middleware::Logger}
#
# Each endpoint can add its own middleware through the builder instance
# provided during initialization.
#
# @example Setting up the environment:
#   Pakyow.setup
#
# @example Running the environment:
#   Pakyow.run
#
module Pakyow
  using Support::DeepFreeze
  using Support::Refinements::Array::Ensurable

  extend Support::DeepFreeze
  unfreezable :logger, :app

  include Support::Hookable
  known_events :configure, :setup, :boot, :fork

  include Support::Configurable

  setting :default_env, :development
  setting :freeze_on_boot, true

  settings_for :server do
    setting :name, :puma
    setting :host, "localhost"
    setting :port, 3000
  end

  settings_for :cli do
    setting :repl, IRB
  end

  settings_for :logger do
    setting :enabled, true
    setting :level, :debug
    setting :formatter, Logger::DevFormatter

    setting :destinations do
      if config.logger.enabled
        [$stdout]
      else
        ["/dev/null"]
      end
    end

    defaults :test do
      setting :enabled, false
    end

    defaults :production do
      setting :level, :info
      setting :formatter, Logger::LogfmtFormatter
    end

    defaults :ludicrous do
      setting :enabled, false
    end
  end

  settings_for :normalizer do
    setting :strict_path, true
    setting :strict_www, false
    setting :require_www, true
  end

  settings_for :tasks do
    setting :paths, ["./tasks", File.expand_path("../tasks", __FILE__)]
    setting :prelaunch, []
  end

  settings_for :redis do
    settings_for :connection do
      setting :url do
        ENV["REDIS_URL"] || "redis://127.0.0.1:6379"
      end

      setting :timeout, 5.0
      setting :driver, nil
      setting :id, nil
      setting :tcp_keepalive, 0
      setting :reconnect_attempts, 1
      setting :inherit_socket, false
    end

    setting :key_prefix, "pw"
  end

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
  SERVERS = %w(puma thin webrick).freeze
  # @api private
  STOP_METHODS = %w(stop! stop).freeze
  # @api private
  STOP_SIGNALS = %w(INT TERM).freeze
  # @api private
  DEFAULT_HANDLER_OPTIONS = {
    puma: { Silent: true }.freeze
  }.freeze

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
    # @param port [Integer] what port to bind Pakyow to
    # @param host [String] what ip address to bind Pakyow to
    # @param server [Symbol] name of the rack handler to use
    #
    # This method also accepts arbitrary options, which are passed directly to the handler.
    #
    def run(port: nil, host: nil, server: nil, **opts)
      @port   = port   || config.server.port
      @host   = host   || config.server.host
      @server = server || config.server.name

      opts.merge!(DEFAULT_HANDLER_OPTIONS.fetch(@server, {}))

      handler(@server).run(to_app, Host: @host, Port: @port, **opts) do |app_server|
        deep_freeze if config.freeze_on_boot

        at_exit do
          stop(app_server)
        end

        STOP_SIGNALS.each do |signal|
          trap(signal) {
            stop(app_server)
          }
        end
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

    # TODO: this is only ever used by tests and should be removed
    # @api private
    def call(env)
      @builder.call(env)
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
  end
end
