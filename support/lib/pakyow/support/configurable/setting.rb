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

        def initialize(name:, default:, configurable:, envar_prefix: nil, &block)
          @name, @default, @block, @configurable, @envar_prefix = name, default, block, configurable, envar_prefix
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
          @value = value unless envar?
        end

        # Returns the current value.
        #
        def value
          unless defined?(@value)
            @value = if envar?
              ENV[envar_name]
            elsif @block
              @configurable.instance_eval(&@block)
            else
              @default
            end
          end

          @value
        end

        private def envar?
          @configurable.envar_prefix && ENV.include?(envar_name)
        end

        private def envar_name
          [@configurable.envar_prefix, @envar_prefix, @name.to_s.upcase].compact.join("__")
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
