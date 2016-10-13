module Pakyow
  module Helpers
    # Methods for configuring an app.
    #
    # @api public
    module Configuring
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
