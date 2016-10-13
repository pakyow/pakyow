require "logger"

require "pakyow/support/hookable"

module Pakyow
  include Support::Hookable

  DEFAULT_ENV    = :development
  DEFAULT_PORT   = 3000
  DEFAULT_HOST   = "localhost".freeze
  DEFAULT_SERVER = :puma

  STOP_METHODS = %i(stop! stop).freeze
  STOP_SIGNALS = %i(INT TERM).freeze

  SERVERS = %i(puma thin webrick).freeze

  known_events :configure, :setup

  class << self
    # TODO: remove this once app is no longer a global concept
    attr_accessor :app

    attr_reader :env, :port, :host, :server, :logger

    def configure(env = :global, &block)
      config[env] = block
    end

    def mount(app, at: nil)
      raise ArgumentError, "Mount path is required" if at.nil?
      mounts[at] = app
    end

    def setup(env: nil)
      hook_around :configure do
        @env = env || DEFAULT_ENV
        load_config(env)
      end

      hook_around :setup do
        init_global_logger

        mounts.each do |path, app|
          app.load_config(@env)

          builder.map path do
            # TODO: define middleware in the configure block instead
            app.middleware.each do |block|
              instance_exec(self, &block)
            end

            run app.new(@env)
          end
        end
      end

      self
    end

    def run(port: nil, host: nil, server: nil)
      @port   = port   || DEFAULT_PORT
      @host   = host   || DEFAULT_HOST
      @server = server || DEFAULT_SERVER

      handler(server).run(builder, Host: @host, Port: @port) do |app_server|
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

    def config
      @config ||= {}
    end

    def mounts
      @mounts ||= {}
    end

    def builder
      @builder ||= Rack::Builder.new
    end

    def load_config(env)
      [:global, env].each do |env_to_load|
        next unless config_for_env = config[env_to_load]
        instance_eval(&config_for_env)
      end
    end

    def init_global_logger
      logs = Config.logger.destinations
      @logger = ::Logger.new(logs.count > 1 ? MultiLog.new(*logs) : logs.first)
      @logger.level = ::Logger.const_get(Config.logger.level.to_s.upcase)
      @logger.formatter = Config.logger.formatter.new
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
