# frozen_string_literal: true

require_relative "deprecator"
require_relative "system"

module Pakyow
  module Support
    # Makes an object deprecatable.
    #
    # @example
    #   class DeprecatedClass
    #     extend Pakyow::Support::Deprecatable
    #
    #     deprecate
    #   end
    #
    #   DeprecatedClass.new
    #   => [deprecation] `DeprecatedClass' is deprecated; solution: do not use
    #
    module Deprecatable
      # Deprecates a target (class, module, or method) with a solution. A deprecation is reported to
      # `Pakyow::Support::Deprecator.global` when the target is used:
      #
      #   * Class: deprecation reported when initialized
      #   * Module: deprecation reported when included or extended
      #   * Method: deprecation reported when the method is called
      #
      def deprecate(target = self, solution: "do not use")
        case target
        when Class
          build_deprecated_initializer(target, solution: solution)
        when Module
          build_deprecated_extender_includer(target, solution: solution)
        else
          build_deprecated_method(target, solution: solution)
        end

        unless ancestors.include?(deprecation_module)
          apply_deprecation_module(self, deprecation_module)
        end
      end

      def self.extended(object)
        super

        object.include DeprecationReferences
      end

      private def deprecation_module
        @__deprecation_module ||= Module.new
      end

      private def apply_deprecation_module(object, deprecation_module)
        case object
        when Class
          object.prepend(deprecation_module)
        when Module
          object.prepend(deprecation_module)
          object.singleton_class.prepend(deprecation_module)
        end
      end

      private def build_deprecated_initializer(target, solution:)
        method_signature = if System.ruby_version < "2.7.0"
          "*"
        else
          "*, **"
        end

        deprecation_module.module_eval <<~CODE
          def initialize(#{method_signature})
            Deprecator.global.deprecated #{target}, solution: #{solution.inspect}

            super
          end
        CODE
      end

      private def build_deprecated_extender_includer(target, solution:)
        method_signature = if System.ruby_version < "2.7.0"
          "*"
        else
          "*, **"
        end

        deprecation_module.module_eval <<~CODE
          def extended(#{method_signature})
            Deprecator.global.deprecated #{target}, solution: #{solution.inspect}

            super
          end

          def included(#{method_signature})
            Deprecator.global.deprecated #{target}, solution: #{solution.inspect}

            super
          end
        CODE
      end

      private def build_deprecated_method(target, solution:)
        target = target.to_sym

        unless deprecatable_methods.include?(target)
          raise RuntimeError, "could not find method `#{target}' to deprecate"
        end

        method_signature = if System.ruby_version < "2.7.0"
          "*"
        else
          "*, **"
        end

        deprecation_module.module_eval <<~CODE
          def #{target}(#{method_signature})
            Deprecator.global.deprecated(*deprecated_method_reference(#{target.inspect}), solution: #{solution.inspect})

            super
          end
        CODE
      end

      private def deprecatable_methods
        context = case self
        when Class, Module
          self
        else
          self.class
        end

        context.instance_methods(false) + context.private_instance_methods(false)
      end

      # @api private
      module DeprecationReferences
        private def deprecated_method_reference(target)
          return self, target
        end
      end
    end
  end
end
