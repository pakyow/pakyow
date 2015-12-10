module Pakyow
  module Helpers
    # Methods run running an app.
    #
    # @api public
    module Running
      # Prepares the app for being staged in one or more environments by
      # loading config(s), middleware, and setting the load path.
      #
      # @api public
      def prepare(*env_or_envs)
        return if prepared?

        # load config for one or more environments
        load_config(*env_or_envs)

        # load each block from middleware stack
        load_middleware

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
        return if running?

        @running = true

        builder.run(stage(*env_or_envs))
        detect_handler.run(builder, Host: config.server.host, Port: config.server.port) do |server|
          trap(:INT)  { stop(server) }
          trap(:TERM) { stop(server) }
        end
      end

      # Returns true if the application is prepared.
      #
      # @api public
      def prepared?
        @prepared
      end

      # Returns true if the application is running.
      #
      # @api public
      def running?
        @running
      end

      # Returns true if the application is staged.
      #
      # @api public
      def staged?
        !Pakyow.app.nil?
      end

      protected

      def builder
        @builder ||= Rack::Builder.new
      end

      def detect_handler
        handlers = ['puma', 'thin', 'mongrel', 'webrick']
        handlers.unshift(config.server.handler) if config.server.handler

        handlers.each do |handler|
          begin
            return Rack::Handler.get(handler)
          rescue LoadError
          rescue NameError
          end
        end
      end

      def stop(server)
        if server.respond_to?('stop!')
          server.stop!
        elsif server.respond_to?('stop')
          server.stop
        else
          # exit ungracefully if necessary...
          Process.exit!
        end
      end

      def load_middleware
        middleware.each do |block|
          instance_exec(builder, &block)
        end
      end
    end
  end
end
