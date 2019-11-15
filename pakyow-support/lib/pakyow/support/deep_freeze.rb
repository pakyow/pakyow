# frozen_string_literal: true

require "delegate"

require "pakyow/support/class_state"
require "pakyow/support/deprecator"

module Pakyow
  module Support
    module DeepFreeze
      def self.extended(base)
        base.extend ClassState
        base.class_state :__insulated_variables, inheritable: true, default: []
      end

      def insulate(*instance_variables)
        @__insulated_variables.concat(
          instance_variables.map { |instance_variable|
            :"@#{instance_variable}"
          }
        ).uniq!
      end

      def unfreezable(*instance_variables)
        Deprecator.global.deprecated :unfreezable, "use `insulate'"

        insulate(*instance_variables)
      end

      [Object, Delegator].each do |klass|
        refine klass do
          def deep_freeze
            if !frozen? && respond_to?(:freeze)
              if !respond_to?(:insulated?) || !insulated?
                freeze
              end

              freezable_variables.each do |name|
                instance_variable_get(name).deep_freeze
              end
            end

            self
          end

          private def freezable_variables
            object = if self.is_a?(Class) || self.is_a?(Module)
              self
            else
              self.class
            end

            if object.respond_to?(:__insulated_variables)
              instance_variables - object.__insulated_variables
            else
              instance_variables
            end
          end
        end
      end

      refine Array do
        def deep_freeze
          unless frozen?
            self.freeze; each(&:deep_freeze)
          end

          self
        end
      end

      refine Hash do
        def deep_freeze
          unless frozen?
            replacement_hash = {}

            each_pair do |key, value|
              replacement_hash[key.deep_freeze] = value.deep_freeze
            end

            replace(replacement_hash); freeze
          end

          self
        end
      end
    end
  end
end
