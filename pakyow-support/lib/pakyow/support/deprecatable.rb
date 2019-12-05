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
          apply_deprecation_module(target, build_deprecated_initializer(target, solution: solution))
        when Module
          apply_deprecation_module(target.singleton_class, build_deprecated_extender_includer(target, solution: solution))
        else
          deprecation_module = build_deprecated_method(target, solution: solution)

          if respond_to?(target.to_s)
            apply_deprecation_module(singleton_class, deprecation_module)
          else
            apply_deprecation_module(self, deprecation_module)
          end
        end
      end

      private def apply_deprecation_module(target, deprecation_module)
        target.prepend(deprecation_module)
      end

      private def build_deprecated_initializer(target, solution:)
        build_module_for_deprecation <<~CODE
          def initialize(*)
            Deprecator.global.deprecated #{target}, #{solution.inspect}

            super
          end
        CODE
      end

      private def build_deprecated_extender_includer(target, solution:)
        build_module_for_deprecation <<~CODE
          def extended(*)
            Deprecator.global.deprecated #{target}, #{solution.inspect}

            super
          end

          def included(*)
            Deprecator.global.deprecated #{target}, #{solution.inspect}

            super
          end
        CODE
      end

      private def build_deprecated_method(target, solution:)
        target = target.to_s

        unless respond_to?(target) || instance_methods.include?(target.to_sym)
          raise RuntimeError, "could not find method `#{target}' to deprecate"
        end

        build_module_for_deprecation <<~CODE
          def #{target}(*)
            Deprecator.global.deprecated self, #{target.to_sym.inspect}, #{solution.inspect}

            super
          end
        CODE
      end

      private def build_module_for_deprecation(code)
        Module.new.tap do |prependable|
          prependable.module_eval(code)
        end
      end
    end
  end
end
