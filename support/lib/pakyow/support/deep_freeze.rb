# frozen_string_literal: true

require "delegate"
require "socket"

require_relative "class_state"
require_relative "extension"
require_relative "hookable"

module Pakyow
  module Support
    module DeepFreeze
      extend Extension

      extend_dependency ClassState
      include_dependency Hookable

      apply_extension do
        events :freeze

        class_state :__insulated_variables, inheritable: true, default: []
      end

      class_methods do
        def insulate(*instance_variables)
          @__insulated_variables.concat(
            instance_variables.map { |instance_variable|
              :"@#{instance_variable}"
            }
          ).uniq!
        end
      end

      [Object, Delegator].each do |klass|
        refine klass do
          def deep_freeze
            if !frozen? && respond_to?(:freeze)
              if !respond_to?(:insulated?) || !insulated?
                if self.class.ancestors.include?(Hookable)
                  performing :freeze do
                    perform_deep_freeze
                  end
                else
                  perform_deep_freeze
                end
              end
            end

            self
          end

          private def perform_deep_freeze
            freeze

            freezable_variables.each do |name|
              instance_variable_get(name).deep_freeze
            end
          end

          private def freezable_variables
            object = if is_a?(Class) || is_a?(Module)
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
            freeze
            each(&:deep_freeze)
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

            replace(replacement_hash)
            freeze
          end

          self
        end
      end

      [IO, Socket, Thread].each do |insulated_class|
        refine insulated_class do
          def insulated?
            true
          end

          # Workaround for (only appears to cause issues in Ruby 2.5):
          # https://ruby-doc.org/core-2.2.2/doc/syntax/refinements_rdoc.html#label-Indirect+Method+Calls
          #
          def respond_to?(name, *)
            super || name == :insulated?
          end
        end
      end
    end
  end
end
