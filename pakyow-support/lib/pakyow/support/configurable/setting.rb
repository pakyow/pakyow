# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Support
    module Configurable
      # @api private
      class Setting
        extend DeepFreeze
        unfreezable :configurable, :value

        def initialize(default:, configurable:, &block)
          @default, @block, @configurable = default, block, configurable
        end

        def set(value)
          @value = value
        end

        def value
          if instance_variable_defined?(:@value)
            @value
          elsif @block
            @configurable.instance_eval(&@block)
          else
            @default
          end
        end

        def update_configurable(configurable)
          @configurable = configurable
        end
      end
    end
  end
end
