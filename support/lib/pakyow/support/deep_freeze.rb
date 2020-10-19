# frozen_string_literal: true

require "delegate"
require "socket"

require_relative "class_state"
require_relative "deprecator"
require_relative "deprecatable"
require_relative "extension"
require_relative "hookable"
require_relative "thread_localizer"

module Pakyow
  module Support
    module DeepFreeze
      # @api private
      def self.prevent_freeze_recursion(object)
        objects_in_freezer[object.object_id] = true

        yield
      ensure
        objects_in_freezer.delete(object.object_id)
      end

      # @api private
      def self.freezing?(object)
        objects_in_freezer[object.object_id]
      end

      # @api private
      def self.objects_in_freezer
        ThreadLocalizer.thread_localized_store[:__pw_freezing_objects] ||= {}
      end

      extend Extension

      extend_dependency ClassState
      include_dependency Hookable

      apply_extension do
        events :freeze

        class_state :__insulated_variables, inheritable: true, default: []
      end

      class_methods do
        extend Deprecatable

        def insulate(*instance_variables)
          @__insulated_variables.concat(
            instance_variables.map { |instance_variable|
              :"@#{instance_variable}"
            }
          ).uniq!
        end

        def unfreezable(*instance_variables)
          insulate(*instance_variables)
        end
        deprecate :unfreezable, solution: "use `insulate'"
      end

      def freeze
        if DeepFreeze.freezing?(self)
          super
        else
          performing :freeze do
            super
          end
        end
      end

      [Object, Delegator].each do |klass|
        refine klass do
          def deep_freeze
            unless DeepFreeze.freezing?(self) || frozen? || !respond_to?(:freeze) || (respond_to?(:insulated?) && insulated?)
              DeepFreeze.prevent_freeze_recursion(self) do
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
            freezable_variables.each do |name|
              instance_variable_get(name).deep_freeze
            end

            freeze
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
          unless DeepFreeze.freezing?(self) || frozen?
            DeepFreeze.prevent_freeze_recursion(self) do
              each(&:deep_freeze)

              freeze
            end
          end

          self
        end
      end

      refine Hash do
        def deep_freeze
          unless DeepFreeze.freezing?(self) || frozen?
            DeepFreeze.prevent_freeze_recursion(self) do
              replacement_hash = {}

              each_pair do |key, value|
                replacement_hash[key.deep_freeze] = value.deep_freeze
              end

              replace(replacement_hash)

              freeze
            end
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
