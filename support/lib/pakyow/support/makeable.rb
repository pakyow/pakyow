# frozen_string_literal: true

require_relative "deprecator"
require_relative "extension"
require_relative "hookable"
require_relative "inflector"
require_relative "isolable"
require_relative "object_name"

module Pakyow
  module Support
    # Make named copies of a class or module.
    #
    # @example
    #   class MakeableObject
    #     include Pakyow::Support::Makeable
    #   end
    #
    #   foo_bar = MakeableObject.make(:foo_bar)
    #
    #   foo_bar.class
    #   => FooBar
    #
    #   foo_bar.ancestors.include?(MakeableObject)
    #   => true
    #
    # @example Making a namespaced object:
    #
    #   class MakeableObject
    #     include Pakyow::Support::Makeable
    #   end
    #
    #   baz = MakeableObject.make(:foo, :bar, :baz)
    #
    #   baz.class
    #   => Foo::Bar::Baz
    #
    #   baz.ancestors.include?(MakeableObject)
    #   => true
    #
    # @example Making a namespaced object from a path:
    #
    #   class MakeableObject
    #     include Pakyow::Support::Makeable
    #   end
    #
    #   baz = MakeableObject.make("foo/bar/baz")
    #
    #   baz.class
    #   => Foo::Bar::Baz
    #
    #   baz.ancestors.include?(MakeableObject)
    #   => true
    #
    module Makeable
      extend Extension

      include_dependency Isolable

      class_methods do
        attr_reader :source_location

        # Make a copy of `self` named `object_name`.
        #
        # @param namespace [Array<Symbol>, ObjectNamespace] The new object's namespace.
        # @param object_name [Symbol, ObjectName] The new object's name.
        # @param set_const [Boolean] If true, a constant will be defined for the new object.
        # @param kwargs [Hash] Additional keys/values to set as instance variables on the new object.
        #
        def make(*namespace, object_name, set_const: true, context: nil, **kwargs, &block)
          context ||= set_const ? TOPLEVEL_BINDING.receiver.class : nil

          if isolated?(object_name, namespace: namespace, context: context)
            object = isolated(object_name, namespace: namespace, context: context)

            define_class_level_state(object, **kwargs)
            extend_with_block(object, &block)
          else
            object = isolate(
              self,
              as: object_name,
              namespace: namespace,
              context: context
            ) {
              if block_given?
                instance_variable_set(:@source_location, block.source_location)
              end

              define_class_level_state(self, **kwargs)

              if ancestors.include?(Hookable)
                call_hooks(:before, :make)
              end

              extend_with_block(self, &block)
            }

            if object.ancestors.include?(Hookable)
              object.call_hooks(:after, :make)
            end
          end

          object
        end

        # @api private
        attr_writer :source_location

        private def type_of_self?(object)
          object.ancestors.include?(ancestors[1])
        end

        private def define_class_level_state(object, **kwargs)
          kwargs.each do |arg, value|
            object.instance_variable_set(:"@#{arg}", value)
          end
        end

        private def extend_with_block(object, &block)
          if block_given?
            object.class_exec(&block)
          end
        end
      end

      apply_extension do
        # Mixin the `make` event for objects that are hookable.
        #
        if ancestors.include?(Hookable)
          events :make
        end
      end
    end
  end
end
