# frozen_string_literal: true

require "forwardable"

require "pakyow/support/class_state"
require "pakyow/support/extension"

require "pakyow/support/definable/registry"

module Pakyow
  module Support
    module Definable
      # @api private
      module State
        extend Extension

        extend_dependency ClassState

        apply_extension do
          class_state :children, default: []
          class_state :parent

          class_state :__defined_state
        end

        class_methods do
          extend Forwardable

          # @api private
          attr_writer :parent

          # Defines a child object, setting `defined_child` and `parent` accordingly.
          #
          def define(*args, **kwargs, &block)
            defined_child = __defined_state.define(*args, **kwargs, &block)
            defined_child.parent = self

            unless children.include?(defined_child)
              children << defined_child
            end

            defined_child
          end

          def inherited(subclass)
            super

            subclass.instance_variable_set(:@__defined_state, Registry.new(
              __defined_state.name, subclass,
              parent: __defined_state.parent,
              builder: __defined_state.builder,
              abstract: false
            ))
          end
        end
      end
    end
  end
end
