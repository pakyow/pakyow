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
        base.extend ClassAPI
      end

      module ClassAPI
        attr_reader :inspectables

        # Sets the instance vars that should be part of the inspection.
        #
        # @param ivars [Array<Symbol>] The list of instance variables.
        #
        def inspectable(*ivars)
          @inspectables = ivars.map { |ivar| "@#{ivar}".to_sym }
        end
      end

      def inspect
        "#<#{self.class.name}:#{self.object_id} " << (self.class.inspectables || []).map {
          |ivar| "#{ivar}=#{self.instance_variable_get(ivar).inspect}"
        }.join(", ") << ">"
      end
    end
  end
end
