# frozen_string_literal: true

require "forwardable"

require "concurrent/hash"

require "pakyow/support/class_state"
require "pakyow/support/extension"

require "pakyow/support/configurable/config"

module Pakyow
  module Support
    # Makes an object configurable, as well as its subclasses.
    #
    # @example
    #   class ConfigurableObject
    #     include Pakyow::Support::Configurable
    #
    #     setting :foo, "default"
    #     setting :bar
    #
    #     defaults :development do
    #       setting :bar, "bar"
    #     end
    #
    #     configurable :baz do
    #       setting :qux, "qux"
    #     end
    #   end
    #
    #   class ConfigurableSubclass < ConfigurableObject
    #     configure :development do
    #       config.foo = "development"
    #     end
    #
    #     configure :production do
    #       config.foo = "production"
    #     end
    #   end
    #
    #   instance = ConfigurableSubclass.new
    #   instance.configure!(:development)
    #
    #   instance.config.foo
    #   # => "development"
    #
    #   instance.config.bar
    #   # => "bar"
    #
    #   instance.config.baz.qux
    #   # => "qux"
    #
    module Configurable
      module CommonMethods
        extend Forwardable

        # @!method setting
        #   Delegates to {config}.
        #
        #   @see Config#setting
        #
        # @!method defaults
        #   Delegates to {config}.
        #
        #   @see Config#defaults
        #
        # @!method configurable
        #   Delegates to {config}.
        #
        #   @see Config#configurable
        #
        def_delegators :config, :setting, :defaults, :configurable

        # Returns the configuration.
        #
        def config
          __config
        end

        # Configures for `environment`.
        #
        def configure!(environment = nil)
          __config.configure_defaults!(environment)

          each_configurable_environment(environment) do |configurable_environment|
            instance_eval(&configurable_environment)
          end
        end

        private def each_configurable_environment(environment)
          if global_environment = __config_environments[:__global]
            yield global_environment
          end

          if environment && specific_environment = __config_environments[environment]
            yield specific_environment
          end
        end
      end

      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__config, default: Config.new(self), inheritable: true
        class_state :__config_environments, default: Concurrent::Hash.new, inheritable: true
      end

      class_methods do
        include CommonMethods

        # Define configuration to be applied when configuring for `environment`.
        #
        def configure(environment = :__global, &block)
          __config_environments[environment] = block
        end

        def inherited(subclass)
          super

          subclass.config.update_configurable(subclass)
        end
      end

      include CommonMethods

      private def __config
        unless defined?(@__config)
          @__config = self.class.__config.dup
          @__config.update_configurable(self)
        end

        @__config
      end

      private def __config_environments
        self.class.__config_environments
      end
    end
  end
end
