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
# - +env.default+ defines the named environment to start when one is not
#   explicitly provided. Default is +:development+.
#
# - +server.default+ defines the application server to use by default.
#   Default is +:puma+.
# - +server.port+ defines the port that the environment runs on.
#   Default is +3000+.
# - +server.host+ defines the host that the environment runs on.
#   Default is "localhost".
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

  setting :freeze_on_boot, true

  settings_for :env do
    setting :default, :development
  end

  settings_for :server do
    setting :default, :puma
    setting :port, 3000
    setting :host, "localhost"
  end

  settings_for :console do
    setting :object do
      IRB
    end
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
    setting :paths, ["./tasks"]
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
  class_state :mounts,     default: {}
  class_state :frameworks, default: {}
  class_state :builder,    default: Rack::Builder.new

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
      @mounts[at] = { app: app, block: block }
    end

    # Prepares the Pakow Environment for running.
    #
    # @param env [Symbol] the environment that Pakyow will be started in
    #
    def setup(env: nil)
      @env = (env ||= config.env.default).to_sym

      performing :configure do
        configure!(env)
      end

      performing :setup do
        init_global_logger

        @mounts.each do |path, mount|
          builder_local_apps = @apps

          @builder.map path do
            app_instance = if defined?(Pakyow::App) && mount[:app].ancestors.include?(Pakyow::App)
              mount[:app].new(env, builder: self, &mount[:block])
            else
              mount[:app].new
            end

            builder_local_apps << app_instance

            run app_instance
          end
        end
      end

      unless @mounts.empty?
        to_app
      end

      self
    end

    def to_app
      if instance_variable_defined?(:@app)
        @app
      else
        @app = builder.to_app.tap do
          call_hooks(:after, :boot)
          @apps.select { |app| app.respond_to?(:booted) }.each(&:booted)
        end
      end
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
      @server = server || config.server.default

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
    end

    # When running the app with a forking server (e.g. Passenger), call this after
    # the process is forked. All defined "after fork" hooks will be called.
    #
    def forked
      call_hooks :after, :fork
    end

    # TODO: this is only ever used by tests and should be removed
    # @api private
    def call(env)
      builder.call(env)
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
      namespace = Support.inflector.camelize(name)
      if const_defined?(namespace)
        klass = const_get(namespace).const_get(:App)
        apps.find { |app|
          app.class == klass
        }
      else
        nil
      end
    end

    def env?(name)
      env == name.to_sym
    end

    def load_tasks
      require "rake"
      Rake::TaskManager.record_task_metadata = true
      config.tasks.paths.uniq.each do |dir_path|
        Dir.glob(File.join(dir_path, "**/*.rake")).each do |file_path|
          Rake.application.add_import(file_path)
        end
      end

      Rake.application.load_imports
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
      Process.exit!
    end
  end
end
