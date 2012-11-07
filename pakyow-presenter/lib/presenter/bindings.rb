module Pakyow
  module Presenter
    class Bindings
      attr_accessor :bindable
      attr_reader :bindings, :mapping

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
        # mapping always overrides fns for a scope
        #TODO single binder instance for scope (bind call)
        if @mapping
          binder = Kernel.const_get(@mapping).new(@bindable)
          binder.value_for_prop(prop)
        elsif binding = @bindings[prop]
          self.instance_exec(&binding)
        else
          # default
          @bindable[prop]
        end
      end

      def merge(bindings)
        @bindings = bindings.bindings.merge(@bindings)
        @mapping = bindings.mapping if bindings.mapping
        self
      end

      def map(klass)
        #TODO make sure klass is subclass of Binder
        @mapping = klass
        self

        # klass must be a subclass of Binder
        # sets flag on self to indicate it's a mapping
        # value_for_prop checks flag, if set call Binder (just like 0.7)
      end
    end
  end
end

