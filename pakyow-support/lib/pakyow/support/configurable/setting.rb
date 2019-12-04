# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/deprecator"

module Pakyow
  module Support
    module Configurable
      # @api private
      class Setting
        using DeepDup

        DEFAULT_SOLUTION = "do not use"

        def initialize(name:, path:, default:, configurable:, deprecated: false, solution: DEFAULT_SOLUTION, &block)
          @name, @path, @default, @configurable, @deprecated, @solution, @block = name, path, default, configurable, deprecated, solution, block
        end

        def initialize_copy(_)
          @default = @default.deep_dup
          super
        end

        def freeze
          value
          super
        end

        def set(value)
          maybe_report_deprecation

          @value = value
        end

        def value
          maybe_report_deprecation

          if instance_variable_defined?(:@value)
            @value
          else
            @value = if @block
              @configurable.instance_eval(&@block)
            else
              @default
            end
          end
        end

        def update_configurable(configurable)
          @configurable = configurable
        end

        private def names
          unless defined?(@names)
            @names = (["config"].concat(@path) << @name).freeze
          end

          @names
        end

        private def deprecation_message
          "#{names.join(".")}"
        end

        private def maybe_report_deprecation
          if @deprecated
            Support::Deprecator.global.deprecated deprecation_message, @solution
          end
        end
      end
    end
  end
end
