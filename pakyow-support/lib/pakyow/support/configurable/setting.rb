# frozen_string_literal: true

require "pakyow/support/deep_dup"

module Pakyow
  module Support
    module Configurable
      # A configurable setting.
      #
      class Setting
        using DeepDup

        def initialize(default:, configurable:, &block)
          @default, @block, @configurable = default, block, configurable
        end

        def initialize_copy(_)
          @default = @default.deep_dup

          super
        end

        def freeze
          # Make sure the value is constructed before freezing.
          #
          value

          super
        end

        # Sets the current value to `value`.
        #
        def set(value)
          @value = value
        end

        # Returns the current value.
        #
        def value
          unless defined?(@value)
            @value = if @block
              @configurable.instance_eval(&@block)
            else
              @default
            end
          end

          @value
        end

        # @api private
        def update_configurable(configurable)
          @configurable = configurable
        end
      end
    end
  end
end
