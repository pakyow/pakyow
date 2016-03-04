require 'rack/builder'
require 'rack/handler'

module Pakyow
  module Helpers
    # Methods run running an app.
    #
    # @api public
    module Running
      STOP_METHODS = ['stop!', 'stop']
      HANDLERS = ['puma', 'thin', 'mongrel', 'webrick']
      SIGNALS = [:INT, :TERM]

      # Prepares the app for being staged in one or more environments by
      # loading config(s), middleware, and setting the load path.
      #
      # @api public
      def prepare(*env_or_envs)
        return true if prepared?

        # load config for one or more environments
        load_env_config(*env_or_envs)

        # load each block from middleware stack
        load_middleware

        # add app/lib to load path
        $:.unshift config.app.src_dir

        @prepared = true
      end

      # Stages the app by preparing and returning an instance. This is
      # essentially everything short of running it.
      #
      # @api public
      def stage(*env_or_envs)
        prepare(*env_or_envs)
        self.new
      end

      # Runs the staged app.
      #
      # @api public
      def run(*env_or_envs)
        return true if running?

        builder.run(stage(*env_or_envs))
        detect_handler.run(builder, Host: config.server.host, Port: config.server.port) do |server|
          SIGNALS.each do |signal|
            trap(signal) { stop(server) }
          end
        end

        @running = true
      end

      # Returns true if the application is prepared.
      #
      # @api public
      def prepared?
        @prepared == true
      end

      # Returns true if the application is running.
      #
      # @api public
      def running?
        @running == true
      end

      # Returns true if the application is staged.
      #
      # @api public
      def staged?
        !Pakyow.app.nil?
      end

      # Returns a rack builder instance.
      #
      # @api public
      def builder
        @builder ||= Rack::Builder.new
      end

      # Returns an instance of the rack handler.
      #
      # @api private
      def detect_handler
        if config.server.handler
          HANDLERS.unshift(config.server.handler).uniq!
        end

        HANDLERS.each do |handler_name|
          begin
            handler = Rack::Handler.get(handler_name)
            return handler unless handler.nil?
          rescue LoadError
          rescue NameError
          end
        end

        raise 'No handler found'
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
    end
  end
end
