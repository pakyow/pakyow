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

      def self.extended(object)
        object.before :reload do
          self.class.send(:load_config)
        end

        object.send(:include, InstanceMethods)
      end

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

        # TODO: move this to a define_resource hook
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

      def load_config(env)
        hook_around :configure do
          config.env = (env || config.app.default_environment).to_sym

          load_env(:global)
          load_env(config.env)
        end
      end

      protected

      def env_config
        @config ||= {}
      end

      def load_env(env)
        config.app_config(&config_for(env))
      end

      def config_for(env)
        env_config.fetch(env) { proc {} }
      end
    end
  end
end
