require "logger"

require "pakyow/support/hookable"
require "pakyow/config/environment"

module Pakyow
  include Support::Hookable

  STOP_METHODS = %i(stop! stop).freeze
  STOP_SIGNALS = %i(INT TERM).freeze

  SERVERS = %i(puma thin webrick).freeze

  known_events :configure, :setup

  class << self
    # TODO: remove this once app is no longer a global concept
    attr_accessor :app

    attr_reader :env, :port, :host, :server, :logger

    def mount(app, at: nil)
      raise ArgumentError, "Mount path is required" if at.nil?
      mounts[at] = app
    end

    def setup(env: nil)
      @env = env ||= DEFAULT_ENV

      hook_around :configure do
        use_config(env)
      end

      hook_around :setup do
        init_global_logger

        mounts.each do |path, app|
          builder.map path do
            run app.new(env: env, builder: self)
          end
        end
      end

      self
    end

    def run(port: nil, host: nil, server: nil)
      @port   = port   || DEFAULT_PORT
      @host   = host   || DEFAULT_HOST
      @server = server || DEFAULT_SERVER

      handler(server).run(builder.to_app, Host: @host, Port: @port) do |app_server|
        STOP_SIGNALS.each do |signal|
          trap(signal) { stop(app_server) }
        end
      end
    end

    def use(middleware, *args)
      builder.use(middleware, *args)
    end

    def call(env)
      builder.call(env)
    end

    protected

    def mounts
      @mounts ||= {}
    end

    def builder
      @builder ||= Rack::Builder.new
    end

    def init_global_logger
      logs = config.logger.destinations
      @logger = ::Logger.new(logs.count > 1 ? MultiLog.new(*logs) : logs.first)
      @logger.level = ::Logger.const_get(config.logger.level.to_s.upcase)
      @logger.formatter = config.logger.formatter.new
    end

    def handler(preferred)
      Rack::Handler.get(preferred) || Rack::Handler.pick(SERVERS)
    end

    def stop(server)
      STOP_METHODS.each do |method|
        if server.respond_to?(method)
          return server.send(method)
        end
      end

      # exit ungracefully
      Process.exit!
    end
  end
end
