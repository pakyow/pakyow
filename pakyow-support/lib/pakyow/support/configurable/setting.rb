# frozen_string_literal: true

require_relative "../deep_dup"

module Pakyow
  module Support
    module Configurable
      # A configurable setting.
      #
      class Setting
        using DeepDup

        attr_reader :name

        def initialize(name:, default:, configurable:, &block)
          @name, @default, @block, @configurable = name, default, block, configurable
        end

        def initialize_copy(_)
          @default = @default.deep_dup

          if defined?(@value)
            @value = @value.deep_dup
          end

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

          self
        end
      end
    end
  end
end
