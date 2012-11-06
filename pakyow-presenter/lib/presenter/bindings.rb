module Pakyow
  module Presenter
    class Bindings
      attr_accessor :bindable
      attr_reader :bindings

      def self.for(block)
        Bindings.new(block)
      end

      def initialize(block)
        @bindings = {}
        self.instance_exec(&block)
      end

      def binding(name, &block)
        @bindings[name] = block
      end

      def value_for_prop(prop)
        return @bindable[prop] unless binding = @bindings[prop]
        self.instance_exec(&binding)
      end
    end
  end
end

