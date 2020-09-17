# frozen_string_literal: true

require "forwardable"

require "concurrent/hash"

require_relative "class_state"
require_relative "extension"
require_relative "system"

require_relative "configurable/config"

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
    #   ConfigurableSubclass.configure!(:development)
    #
    #   instance = ConfigurableSubclass.new
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
    # = Configuring with environment variables
    #
    # Configurable objects can define a prefix that allows for settings to be configured through
    # environment variables. This behavior can be opted into with the `envar` class method:
    #
    #   class ConfigurableObject
    #     include Pakyow::Support::Configurable
    #
    #     envar "MY_NAMESPACE"
    #
    #     configurable :foo do
    #       setting :bar
    #     end
    #   end
    #
    # Environment variable names should be named with the following convention:
    #
    #   * {envar}__GROUP_NAME__SETTING_NAME
    #
    # The `foo.bar` setting in the above example can be set with the following environment variable:
    #
    #   * MY_NAMESPACE__FOO__BAR
    #
    # Environment variables take precedence over any configured value.
    #
    module Configurable
      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__config, default: Config.make(:config, context: self, __configurable: self), inheritable: true
        class_state :__config_environments, default: Concurrent::Hash.new, inheritable: true
        class_state :__config_envar, inheritable: true
      end

      class_methods do
        extend Forwardable

        # @!method setting
        #   @see Config#setting
        #
        # @!method defaults
        #   @see Config#defaults
        #
        # @!method configurable
        #   @see Config#configurable
        #
        def_delegators :__config, :setting, :defaults, :configurable

        def freeze
          # Make sure the config is constructed before freezing.
          #
          config

          super
        end

        # Returns the configuration.
        #
        def config
          @config ||= __config.new(self)
        end

        # Define configuration to be applied when configuring for `environment`.
        #
        def configure(environment = :__global, &block)
          __config_environments[environment] = block
        end

        # Configures for `environment`.
        #
        def configure!(environment = nil)
          environment = environment&.to_sym

          __config.configure_defaults!(environment)

          each_configurable_environment(environment) do |configurable_environment|
            instance_eval(&configurable_environment)
          end
        end

        # Configures the environment variable prefix.
        #
        def envar(prefix)
          @__config_envar = prefix.to_s.upcase
        end

        def envar_prefix
          @__config_envar
        end

        private def each_configurable_environment(environment)
          if global_environment = __config_environments[:__global]
            yield global_environment
          end

          if environment && specific_environment = __config_environments[environment]
            yield specific_environment
          end
        end

        def inherited(subclass)
          super

          subclass.instance_variable_set(:@__config, __config.make(:config, context: subclass, __configurable: subclass))
        end
      end

      prepend_methods do
        if System.ruby_version < "2.7.0"
          def initialize(*)
            __common_configurable_initialize; super
          end
        else
          def initialize(*, **)
            __common_configurable_initialize; super
          end
        end

        private def __common_configurable_initialize
          @config = self.class.config.dup.update_configurable(self)
        end
      end

      attr_reader :config

      def envar_prefix
        self.class.envar_prefix
      end
    end
  end
end
