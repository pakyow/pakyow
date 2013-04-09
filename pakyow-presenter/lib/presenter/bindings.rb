module Pakyow
  module Presenter
    class Bindings
      attr_accessor :bindable
      attr_reader :bindings, :binding_options, :mapping

      include GeneralHelpers

      def fn(name, &block)
        @funcs[name] = block and return if block
        @funcs[name]
      end

      def self.for(block)
        Bindings.new(block)
      end

      def initialize(block = nil)
        @funcs = {}
        @bindings = {}
        @binding_options = {}
        self.instance_exec(&block) if block
      end

      def binding(name, func = nil, &block)
        @bindings[name] = func || block
      end

      def options(name, func = nil, &block)
        @binding_options[name] = func || block
      end

      def options_for_prop(prop)
        if fn = @binding_options[prop]
          self.instance_exec(&fn)
        end
      end

      def prop?(prop)
        @bindings.key?(prop)
      end

      def value_for_prop(prop)
        # mapping always overrides fns for a scope
        if @mapping
          @binder ||= Kernel.const_get(@mapping).new(@bindable)
          @binder.value_for_prop(prop)
        elsif binding = @bindings[prop]
          case binding.arity
            when 0
              self.instance_exec(&binding)
            when 1
              self.instance_exec(@bindable[prop], &binding)
          end
        else
          # default
          @bindable[prop]
        end
      end

      # Merges a Bindings instance or Hash of bindings to self
      def merge(bindings)
        if bindings.is_a?(Hash)
          @bindings = @bindings.merge(bindings)
        elsif bindings
          @bindings = bindings.bindings.merge(@bindings)
          @mapping = bindings.mapping if bindings.mapping
          @binding_options = bindings.binding_options if bindings.binding_options && !bindings.binding_options.empty?
        end
        
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

      def restful(route_group)
        self.binding(:action) {
          routes = router.group(route_group)
          return_data = {}

          if id = bindable[:id]
            return_data[:content] = lambda { |content|
              '<input type="hidden" name="_method" value="put">' + content
            }

            action = routes.path(:update, :id => id)
          else
            action = routes.path(:create)
          end

          return_data[:action] = action
          return_data[:method] = 'post' 
          return_data
        }
      end
    end
  end
end

