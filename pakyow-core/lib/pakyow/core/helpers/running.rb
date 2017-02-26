require "rack/builder"
require "rack/handler"

module Pakyow
  module Helpers
    # Methods run running an app.
    #
    # @api public
    module Running
      HANDLERS = %i(puma thin webrick)

      STOP_METHODS = %i(stop! stop)
      STOP_SIGNALS = %i(INT TERM)

      # Prepares the app for being staged by configuring the environment,
      # loading middleware, and adding the source directory to the load path.
      #
      # @api public
      def prepare(env)
        load_env_config(env)
        load_middleware
        $LOAD_PATH.unshift config.app.src_dir
      end

      # Stages the app by preparing and returning an instance. This is
      # essentially everything short of running it.
      #
      # @api public
      def stage(env)
        prepare(env)
        self.new
      end

      # Runs the staged app.
      #
      # @api public
      def run(env, **opts)
        builder.run(stage(env))
        handler.run(builder, Host: config.server.host, Port: config.server.port, **opts) do |server|
          STOP_SIGNALS.each do |signal|
            trap(signal) { stop(server) }
          end
        end
      end

      # Returns a rack builder instance.
      #
      # @api public
      def builder
        @builder ||= Rack::Builder.new
      end

      protected

      def stop(server)
        STOP_METHODS.each do |method|
          if server.respond_to?(method)
            return server.send(method)
          end
        end

        # exit ungracefully
        Process.exit!
      end

      def load_middleware
        middleware.each do |block|
          instance_exec(builder, &block)
        end
      end

      def handler
        config.server.handler || Rack::Handler.pick(HANDLERS)
      end
    end
  end
end
