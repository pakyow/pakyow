# frozen_string_literal: true

require "forwardable"

require "concurrent/hash"

require "pakyow/support/class_state"

require "pakyow/support/configurable/config"

module Pakyow
  module Support
    # Makes an object configurable.
    #
    #   class ConfigurableObject
    #     include Configurable
    #
    #     setting :foo, "default"
    #     setting :bar
    #
    #     defaults :development do
    #       setting :bar, "bar"
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
    #   instance.configure! :development
    #
    #   instance.config.foo
    #   # => "development"
    #   instance.config.bar
    #   # => "bar"
    #
    module Configurable
      # @api private
      def self.included(base)
        base.extend ClassState
        base.class_state :__config, default: Config.new(base), inheritable: true
        base.class_state :__config_environments, default: Concurrent::Hash.new, inheritable: true

        unless base.instance_of?(Module)
          base.prepend Initializer
        end

        base.include CommonMethods
        base.extend  ClassMethods, CommonMethods
      end

      private def __config_environments
        self.class.__config_environments
      end

      module Initializer
        # @api private
        def initialize(*)
          @__config = self.class.__config.dup
          @__config.update_configurable(self)
          super
        end
      end

      module ClassMethods
        # Define configuration to be applied when configuring for an environment.
        #
        def configure(environment = :__global, &block)
          @__config_environments[environment] = block
        end

        # @api private
        def inherited(subclass)
          super
          subclass.config.update_configurable(subclass)
        end
      end

      module CommonMethods
        extend Forwardable
        def_delegators :@__config, :setting, :deprecated_setting, :defaults, :configurable, :deprecated_configurable

        def config
          @__config
        end

        # Configures the object for an environment.
        #
        def configure!(configured_environment = nil)
          @__config.configure_defaults!(configured_environment)

          [:__global, configured_environment].compact.map(&:to_sym).select { |environment|
            __config_environments.key?(environment)
          }.each do |environment|
            instance_eval(&__config_environments[environment])
          end
        end
      end
    end
  end
end
