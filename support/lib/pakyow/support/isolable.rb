# frozen_string_literal: true

require_relative "extension"
require_relative "inflector"
require_relative "object_namespace"
require_relative "object_name"

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
        attr_reader :object_name

        # Isolates `object_to_isolate` within `self` or `context`, evaluating the given block in context.
        #
        def isolate(object_to_isolate, as: default_omitted = true, namespace: [], context: isolable_context, &block)
          object_to_isolate = ensure_object(object_to_isolate)

          as = if default_omitted
            Support.inflector.demodulize(object_to_isolate.name)
          else
            as
          end

          isolated_object_name = if as
            build_isolable_object_name(*namespace, as)
          end

          isolated_object = if isolated_object_name && context
            isolation_target = ensure_isolable_namespace(*isolated_object_name.namespace.parts).inject(context) { |target_for_part, object_name_part|
              constant_name = Support.inflector.camelize(object_name_part.to_s)

              unless constant_defined_on_target?(constant_name, target_for_part)
                target_for_part.const_set(constant_name, Module.new)
              end

              target_for_part.const_get(constant_name)
            }

            isolated_constant_name = Support.inflector.demodulize(isolated_object_name.constant)

            if constant_defined_on_target?(isolated_constant_name, isolation_target)
              isolation_target.const_get(isolated_constant_name)
            else
              newly_isolated_object = define_isolated_object(object_to_isolate)
              isolation_target.const_set(isolated_constant_name, newly_isolated_object)
              newly_isolated_object
            end
          else
            define_isolated_object(object_to_isolate)
          end

          unless isolated_object_name.nil? || isolated_object.instance_variable_defined?(:@object_name)
            isolated_object.instance_variable_set(:@object_name, isolated_object_name)
          end

          isolated_object.class_eval(&block) if block

          isolated_object
        end

        # Returns true if `class_name` is isolated within `self` or `context`.
        #
        def isolated?(class_name, namespace: [], context: isolable_context)
          class_name = ensure_isolable_class_name(class_name)
          isolation_target = resolve_isolation_target(namespace, context)

          constant_defined_on_target?(class_name, isolation_target)
        end

        # Returns the isolated class for `class_name`, evaluating the given block in context.
        #
        def isolated(class_name, namespace: [], context: isolable_context, &block)
          class_name = ensure_isolable_class_name(class_name)
          isolation_target = resolve_isolation_target(namespace, context)

          if isolation_target && isolated?(class_name, context: isolation_target)
            isolated_class = isolation_target.const_get(class_name)
            isolated_class.class_eval(&block) if block
            isolated_class
          end
        end

        # @api public
        private def isolable_context
          self
        end

        private def constant_defined_on_target?(constant, target)
          !target.nil? && target.const_defined?(constant, false)
        rescue NameError
          false
        end

        private def resolve_isolation_target(namespace, context)
          ensure_isolable_namespace(*namespace).inject(context) { |target_for_part, object_name_part|
            constant = ensure_isolable_class_name(object_name_part)

            if constant_defined_on_target?(constant, target_for_part)
              target_for_part.const_get(constant)
            end
          }
        end

        private def build_isolable_object_name(*namespace, object_name)
          unless object_name.is_a?(ObjectName)
            object_name_parts = Support.inflector.underscore(object_name.to_s).split("/").reject(&:empty?)
            object_name = object_name_parts.pop || :index

            if object_name_parts.any?
              namespace = case namespace
              when ObjectNamespace
                ObjectNamespace.new(*namespace.parts, *object_name_parts)
              when Array
                namespace + object_name_parts
              when NilClass
                object_name_parts
              end
            end
          end

          object_namespace = if namespace.any?
            case namespace.first
            when ObjectNamespace
              namespace.first
            else
              ObjectNamespace.new(*namespace)
            end
          end

          if object_name.is_a?(ObjectName)
            if object_namespace.is_a?(ObjectNamespace) && object_name.namespace != object_namespace
              object_name.rebase(object_namespace)
            end
          else
            object_name = ObjectName.new(object_namespace || ObjectNamespace.new, object_name)
          end

          object_name
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

        private def ensure_isolable_class_name(class_name)
          Support.inflector.camelize(class_name.to_s)
        end

        private def ensure_isolable_namespace(*namespace)
          if namespace.first.is_a?(ObjectNamespace)
            namespace.first.parts
          else
            namespace
          end
        end
      end

      # Convenience method for getting an isolated object through an instance.
      #
      def isolated(class_name, namespace: [], context: self.class.send(:isolable_context), &block)
        self.class.isolated(class_name, namespace: namespace, context: context, &block)
      end
    end
  end
end
