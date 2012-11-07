module Pakyow
  module Presenter
    class Bindings
      attr_accessor :bindable
      attr_reader :bindings

      def func(name, &block)
        @funcs[name] = block and return if block
        @funcs[name]
      end

      def self.for(block)
        Bindings.new(block)
      end

      def initialize(block = nil)
        @funcs = {}
        @bindings = {}
        self.instance_exec(&block) if block
      end

      def binding(name, func = nil, &block)
        @bindings[name] = func || block
      end

      def value_for_prop(prop)
        return @bindable[prop] unless binding = @bindings[prop]
        self.instance_exec(&binding)
      end

      def merge(bindings)
        @bindings = bindings.bindings.merge(@bindings)
        self
      end
    end
  end
end

