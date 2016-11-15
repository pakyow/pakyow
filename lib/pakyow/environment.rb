require "irb"
require "rack"
require "logger"

require "pakyow/support/hookable"
require "pakyow/support/configurable"

require "pakyow/logger"
require "pakyow/middleware"

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
# The following config settings are available within the environment:
#
# - *env.default*: named environment to start when one is not explicitly provided  
#   _default_: development
#
# - *server.default*: the application server to use by default  
#   _default_: puma
# - *server.port*: the port that the environment runs on  
#   _default_: 3000
# - *server.host*: the host that the environment runs on  
#   _default_: localhost
#
# - *logger.enabled*: whether or not logging is enabled  
#   _default_: true
# - *logger.level*: what level to log at  
#   _default_: :debug, :info (production)
# - *logger.formatter*: the formatter to use when logging  
#   _default_: {Logger::DevFormatter}, {Logger::LogfmtFormatter} (production)
# - *logger.destinations*: where logs are output to  
#   _default_: $stdout (when logger.enabled), /dev/null (for test environment or when logger is disabled)
#
# - *normalizer.strict_path*: whether or not request paths are normalized  
#   _default_: true
# - *normalizer.strict_www*: whether or not the www subdomain are normalized  
#   _default_: false
# - *normalizer.require_www*: whether or not to require www in the hostname  
#   _default_: true
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
  include Support::Hookable
  known_events :configure, :setup, :fork

  include Support::Configurable

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

  # Loads the default middleware stack.
  #
  before :setup do
    use Rack::ContentType, "text/html;charset=utf-8"
    use Rack::ContentLength
    use Rack::Head
    use Rack::MethodOverride
    use Middleware::JSONBody
    use Middleware::Normalizer
    use Middleware::Logger
  end

  class << self
    # Name of the environment
    #
    # @api public
    attr_reader :env

    # Port that the environment is running on
    #
    # @api public
    attr_reader :port

    # Host that the environment is running on
    #
    # @api public
    attr_reader :host

    # Name of the app server running in the environment
    #
    # @api public
    attr_reader :server

    # Logger instance for the environment
    #
    # @api public
    attr_reader :logger

    # Mounts an app at a path.
    #
    # The app can be any rack endpoint, but must implement an
    # initializer like {App#initialize}.
    #
    # @param app the rack endpoint to mount
    # @param at [String] where the endpoint should be mounted
    #
    # @api public
    def mount(app, at: nil, &block)
      raise ArgumentError, "Mount path is required" if at.nil?
      mounts[at] = { app: app, block: block }
    end

    # Prepares the Pakow Environment for running.
    #
    # @param env [Symbol] the environment that Pakyow will be started in
    #
    # @api public
    def setup(env: nil)
      @env = env ||= config.env.default

      hook_around :configure do
        use_config(env)
      end

      hook_around :setup do
        init_global_logger

        mounts.each do |path, mount|
          builder.map path do
            app_instance = if defined?(Pakyow::App) && mount[:app].ancestors.include?(Pakyow::App)
                             mount[:app].new(env, builder: self, &mount[:block])
                           else
                             mount[:app].new
                           end

            run app_instance
          end
        end
      end

      self
    end

    # Starts the Pakyow Environment.
    #
    # @param port [Integer] what port to bind Pakyow to
    # @param host [String] what ip address to bind Pakyow to
    # @param server [Symbol] name of the rack handler to use
    #
    # @api public
    def run(port: nil, host: nil, server: nil)
      @port   = port   || config.server.port
      @host   = host   || config.server.host
      @server = server || config.server.default

      handler(@server).run(builder.to_app, Host: @host, Port: @port) do |app_server|
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
    # @api public
    def fork
      forking
      yield
      forked
    end

    # When running the app with a forking server (e.g. Passenger), call this before
    # the process is forked. All defined "before fork" hooks will be called.
    #
    # @api public
    def forking
      call_hooks :before, :fork
    end

    # When running the app with a forking server (e.g. Passenger), call this after
    # the process is forked. All defined "after fork" hooks will be called.
    #
    # @api public
    def forked
      call_hooks :after, :fork
    end

    # @api private
    def call(env)
      builder.call(env)
    end

    # @api private
    def reset
      @env = nil
      @port = nil
      @host = nil
      @server = nil
      @mounts = nil
      @builder = nil
      @logger = nil
      config.reset
    end

    protected

    def use(middleware, *args)
      builder.use(middleware, *args)
    end

    def mounts
      @mounts ||= {}
    end

    def builder
      @builder ||= Rack::Builder.new
    end

    def init_global_logger
      logs = config.logger.destinations
      @logger = ::Logger.new(logs.count > 1 ? Logger::MultiLog.new(*logs) : logs.first)
      @logger.level = ::Logger.const_get(config.logger.level.to_s.upcase)
      @logger.formatter = config.logger.formatter.new
    end

    # @api private
    SERVERS = %w(puma thin webrick).freeze

    def handler(preferred)
      Rack::Handler.get(preferred) || Rack::Handler.pick(SERVERS)
    end

    # @api private
    STOP_METHODS = %w(stop! stop).freeze
    # @api private
    STOP_SIGNALS = %w(INT TERM).freeze

    def stop(server)
      STOP_METHODS.each do |method|
        return server.send(method) if server.respond_to?(method)
      end

      # exit ungracefully
      Process.exit!
    end
  end
end
