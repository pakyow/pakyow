module Pakyow
  module Helpers
    # Methods for configuring an app.
    #
    # @api public
    module Configuring
      RESOURCE_ACTIONS = {
        core: Proc.new { |app, set_name, path, block|
          app.routes(set_name) { restful(set_name, path, &block) }
        }
      }

      module InstanceMethods
        # Convenience method for defining routes on an app instance.
        #
        # @api public
        def routes(set_name = :main, &block)
          self.class.routes(set_name, &block)
          load_routes
        end

        # Convenience method for defining resources on an app instance.
        #
        # @api public
        def resource(set_name, path, &block)
          self.class.resource(set_name, path, &block)
        end
      end

      def self.extended(object)
        object.before :reload do
          self.class.send(:load_config)
        end

        object.send(:include, InstanceMethods)
      end

      # Absolute path to the file containing the app definition.
      #
      # @api private
      attr_reader :path

      # Defines an app
      #
      # @api public
      def define(&block)
        raise ArgumentError, 'Expected a block' unless block_given?

        # Sets the path to the file containiner the app definition for later reloading.
        @path = String.parse_path_from_caller(caller[0])

        instance_eval(&block)
        self
      end

      # Defines a route set.
      #
      # @api public
      def routes(set_name = :main, &block)
        return @routes ||= {} unless block_given?
        routes[set_name] = block
        self
      end

      # Defines a resource.
      #
      # @api public
      def resource(set_name, path, &block)
        raise ArgumentError, 'Expected a block' unless block_given?

        RESOURCE_ACTIONS.each do |plugin, action|
          action.call(self, set_name, path, block)
        end
      end

      # Accepts block to be added to middleware stack.
      #
      # @api public
      def middleware(&block)
        return @middleware ||= [] unless block_given?
        middleware << block
      end

      # Creates an environment.
      #
      # @api public
      def configure(env = :global, &block)
        raise ArgumentError, 'Expected a block' unless block_given?
        env_config[env] = block
      end

      protected

      def load_config
        # reload the app file
        load(config.app.path)

        # reset config
        envs = config.app.loaded_envs
        config.reset

        # reload config
        load_env_config(*envs)
      end

      def load_env_config(*env_or_envs)
        hook_around :configure do
          envs = build_envs(env_or_envs)

          config.app.loaded_envs = envs
          config.env = envs.first

          envs.each do |env|
            load_env(env)
          end

          load_env(:global)

          Pakyow.configure_logger
        end
      end

      def env_config
        @config ||= {}
      end

      def build_envs(env_or_envs)
        envs = Array.ensure(env_or_envs)
        envs = (envs.empty? || envs.first.nil?) ? [config.app.default_environment] : envs
        envs.map!(&:to_sym)
      end

      def load_env(env)
        config.app_config(&env_config.fetch(env))
      rescue KeyError
      end
    end
  end
end
