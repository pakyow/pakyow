# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  module Support
    # Customized inspectors for your objects.
    #
    # @example
    #   class FooBar
    #     include Pakyow::Support::Inspectable
    #     inspectable :foo
    #
    #     def initialize
    #       @foo = :foo
    #       @bar = :bar
    #     end
    #   end
    #
    #   FooBar.instance.inspect
    #   => #<FooBar:0x007fd3330248c0 @foo=:foo>
    #
    module Inspectable
      def self.included(base)
        base.extend ClassMethods
        base.extend ClassState unless base.ancestors.include?(ClassState)
        base.class_state :__inspectables, inheritable: true, default: []
      end

      module ClassMethods
        # Sets the instance vars that should be part of the inspection.
        #
        # @param ivars [Array<Symbol>] The list of instance variables.
        #
        def inspectable(*ivars)
          @__inspectables = ivars.map { |ivar| "@#{ivar}".to_sym }
        end
      end

      def inspect
        inspection = String.new("#<#{self.class}:#{self.object_id}")

        if self.class.__inspectables.any?
          inspection << " " + self.class.__inspectables.map { |ivar|
            "#{ivar}=#{self.instance_variable_get(ivar).inspect}"
          }.join(", ")
        end

        inspection.strip << ">"
      end
    end
  end
end
