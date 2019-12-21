# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/inflector"
require "pakyow/support/object_namespace"

module Pakyow
  module Support
    # Create isolated classes and modules within an object.
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Isolable
    #
    #     isolate Controller do
    #       def self.some_behavior
    #         puts "it works"
    #       end
    #     end
    #   end
    #
    #   # Isolated objects are subclasses.
    #   #
    #   Application::Controller.ancestors.include?(Controller)
    #   => true
    #
    #   # Like any subclass, isolated objects can extend the parent.
    #   #
    #   Application::Controller.some_behavior
    #   => it works
    #
    #   # Parent objects are unmodified.
    #   #
    #   Controller.some_behavior
    #   => NoMethodError (undefined method `some_behavior' for Controller:Class)
    #
    module Isolable
      extend Extension

      class_methods do
        # Isolates `object_to_isolate` within `self` or `binding`, evaluating the given block in context.
        #
        def isolate(*namespace, object_to_isolate, binding: self, &block)
          object_to_isolate = ensure_object(object_to_isolate)

          isolated_class_name = Support.inflector.demodulize(object_to_isolate.to_s).to_sym

          isolation_target = ensure_isolatable_namespace(*namespace).inject(binding) { |target_for_part, object_name_part|
            constant_name = Support.inflector.camelize(object_name_part.to_s)

            unless target_for_part.const_defined?(constant_name, false)
              target_for_part.const_set(constant_name, Module.new)
            end

            target_for_part.const_get(constant_name)
          }

          unless isolation_target.const_defined?(isolated_class_name, false)
            isolation_target.const_set(isolated_class_name, define_isolated_object(object_to_isolate))
          end

          isolated(*namespace, isolated_class_name, binding: binding).tap do |defined_subclass|
            defined_subclass.class_eval(&block) if block_given?
          end
        end

        # Returns true if `class_name` is isolated within `self` or `binding`.
        #
        def isolated?(*namespace, class_name, binding: self)
          isolation_target = ensure_isolatable_namespace(*namespace).inject(binding) { |target_for_part, object_name_part|
            target_for_part.const_get(Support.inflector.camelize(object_name_part.to_s))
          }

          isolation_target.const_defined?(Support.inflector.camelize(class_name.to_s))
        end

        # Returns the isolated class for `class_name`, evaluating the given block in context.
        #
        def isolated(*namespace, class_name, binding: self, &block)
          class_name = Support.inflector.camelize(class_name.to_s)

          isolation_target = ensure_isolatable_namespace(*namespace).inject(binding) { |target_for_part, object_name_part|
            target_for_part.const_get(Support.inflector.camelize(object_name_part.to_s))
          }

          if isolated?(class_name, binding: isolation_target)
            isolation_target.const_get(class_name).tap do |isolated_class|
              isolated_class.class_eval(&block) if block_given?
            end
          else
            nil
          end
        end

        private def define_isolated_object(object)
          case object
          when Class
            Class.new(object)
          when Module
            Module.new do
              object.included_modules.each do |included_module|
                include included_module
              end

              object.singleton_class.included_modules.each do |extended_module|
                extend extended_module
              end

              if respond_to?(:inherit_extension)
                inherit_extension(object)
              end
            end
          end
        end

        private def ensure_object(object)
          unless object.is_a?(Class) || object.is_a?(Module)
            object = const_get(Support.inflector.camelize(object.to_s))
          end

          object
        end

        private def ensure_isolatable_namespace(*namespace)
          if namespace.first.is_a?(ObjectNamespace)
            namespace.first.parts
          else
            namespace
          end
        end
      end

      # Convenience method for getting an isolated object through an instance.
      #
      def isolated(*namespace, class_name, binding: self.class, &block)
        self.class.isolated(class_name, binding: binding, &block)
      end
    end
  end
end
