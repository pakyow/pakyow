# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/extension"

module Pakyow
  module Support
    # Customize the inspector for an object.
    #
    # @example
    #   class FooBar
    #     include Pakyow::Support::Inspectable
    #     inspectable :@foo, :baz
    #
    #     def initialize
    #       @foo = :foo
    #       @bar = :bar
    #     end
    #
    #     def baz
    #       :baz
    #     end
    #   end
    #
    #   FooBar.instance.inspect
    #   => #<FooBar:0x007fd3330248c0 @foo=:foo baz=:baz>
    #
    module Inspectable
      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__inspectables, inheritable: true, default: []
      end

      class_methods do
        # Sets the instance vars and public methods that should be part of the inspection.
        #
        # @param inspectables [Array<Symbol>] The list of instance variables and public methods.
        #
        def inspectable(*inspectables)
          @__inspectables = inspectables.map(&:to_sym)
        end
      end

      # Recursion protection based on:
      #   https://stackoverflow.com/a/5772445
      #
      def inspect
        inspection = String.new("#<#{self.class}:#{self.object_id}")

        if recursive_inspect?
          "#{inspection} ...>"
        else
          prevent_inspect_recursion do
            if self.class.__inspectables.any?
              inspection << " " + self.class.__inspectables.map { |inspectable|
                value = if inspectable.to_s.start_with?("@")
                  instance_variable_get(inspectable)
                else
                  send(inspectable)
                end

                "#{inspectable}=#{value.inspect}"
              }.join(", ")
            end

            inspection.strip << ">"
          end
        end
      end

      private

      def inspected_objects
        Thread.current[:inspected_objects] ||= {}
      end

      def prevent_inspect_recursion
        inspected_objects[object_id] = true; yield
      ensure
        inspected_objects.delete(object_id)
      end

      def recursive_inspect?
        inspected_objects[object_id]
      end
    end
  end
end
