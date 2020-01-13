# frozen_string_literal: true

require "pakyow/support/deprecator"

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
      end

      def self.extended(object)
        super

        object.class_eval do
          apply_deprecation_module(self, deprecation_module)

          include DeprecationReferences
        end
      end

      private def deprecation_module
        @__deprecation_module ||= Module.new
      end

      private def apply_deprecation_module(object, deprecation_module)
        case object
        when Module
          object.singleton_class.prepend(deprecation_module)
        end

        object.prepend(deprecation_module)
      end

      private def build_deprecated_initializer(target, solution:)
        deprecation_module.module_eval <<~CODE
          def initialize(*)
            Deprecator.global.deprecated #{target}, solution: #{solution.inspect}

            super
          end
        CODE
      end

      private def build_deprecated_extender_includer(target, solution:)
        deprecation_module.module_eval <<~CODE
          def extended(*)
            Deprecator.global.deprecated #{target}, solution: #{solution.inspect}

            super
          end

          def included(*)
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

        deprecation_module.module_eval <<~CODE
          def #{target}(*)
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

        context.instance_methods
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
