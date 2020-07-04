# frozen_string_literal: true

require_relative "class_state"
require_relative "extension"
require_relative "thread_localizer"

module Pakyow
  module Support
    # Customized inspection for any object.
    #
    # There are two modes:
    #
    #   1) Inspecting specific instance variables and methods.
    #
    #      class FooBar
    #        include Pakyow::Support::Inspectable
    #        inspectable :@foo, :baz
    #
    #        def initialize
    #          @foo = :foo
    #          @bar = :bar
    #        end
    #
    #        def baz
    #         :baz
    #        end
    #      end
    #
    #      FooBar.instance.inspect
    #      => #<FooBar:0x007fd3330248c0 @foo=:foo baz=:baz>
    #
    #   2) Inspecting everything *except* one or more instance variables.
    #
    #      class FooBar
    #        include Pakyow::Support::Inspectable
    #        uninspectable :@foo
    #
    #        def initialize
    #          @foo = :foo
    #          @bar = :bar
    #        end
    #      end
    #
    #      FooBar.instance.inspect
    #      => #<FooBar:0x007fd3330248c0 @bar=:bar>
    #
    module Inspectable
      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__inspectables, inheritable: true, default: []
        class_state :__uninspectables, inheritable: true, default: []
      end

      class_methods do
        # Sets the instance vars and public methods that should be part of the inspection.
        #
        # @param inspectables [Array<Symbol>] The list of instance variables and public methods.
        #
        def inspectable(*inspectables)
          @__inspectables = inspectables.map(&:to_sym)
        end

        # Sets the instance vars and public methods that should *not* be part of the inspection.
        #
        # @param uninspectables [Array<Symbol>] The list of instance variables and public methods.
        #
        def uninspectable(*uninspectables)
          @__uninspectables = uninspectables.map(&:to_sym)
        end
      end

      # Recursion protection based on:
      #   https://stackoverflow.com/a/5772445
      #
      def inspect
        inspection = String.new("#<#{self.class}:#{object_id}")

        if recursive_inspect?
          "#{inspection} ...>"
        else
          prevent_inspect_recursion do
            each_inspectable do |inspectable|
              value = if inspectable.to_s.start_with?("@")
                instance_variable_get(inspectable)
              else
                send(inspectable)
              end

              inspection << ", #{inspectable}=#{value.inspect}"
            end

            inspection.strip << ">"
          end
        end
      end

      private

      def each_inspectable
        inspectables = if self.class.__inspectables.any?
          self.class.__inspectables
        else
          instance_variables
        end

        inspectables.each do |inspectable|
          unless self.class.__uninspectables.include?(inspectable)
            yield inspectable
          end
        end
      end

      def inspected_objects
        ThreadLocalizer.thread_localized_store[:__pw_inspected_objects] ||= {}
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
