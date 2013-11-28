module Pakyow
  module Presenter
    # A singleton that manages route sets.
    #
    class Binder
      include Singleton
      include Helpers

      attr_reader :sets

      def initialize
        @sets = {}
      end

      #TODO want to do this for all sets?
      def reset
        @sets = {}
        self
      end

      # Creates a new set.
      #
      def set(name, &block)
        @sets[name] = BinderSet.new
        @sets[name].instance_exec(&block)
      end

      def value_for_prop(prop, scope, bindable, bindings = {}, context)
        @context = context
        binding = nil
        @sets.each {|set|
          binding = set[1].match_for_prop(prop, scope, bindable, bindings)
          break if binding
        }

        if binding
          binding_eval = BindingEval.new(prop, bindable, context)

          case binding.arity
          when 0
            binding_eval.instance_exec(&binding)
          when 1
            self.instance_exec(bindable, &binding)
          when 2
            self.instance_exec(bindable, binding_eval.value, &binding)
          end
        else
          # default
          prop_value_for_bindable(bindable, prop)
        end
      end

      def prop_value_for_bindable(bindable, prop)
        return bindable[prop] if bindable.is_a?(Hash)
        return bindable.send(prop) if bindable.class.method_defined?(prop)
      end

      def options_for_prop(*args)
        match = nil
        @sets.each {|set|
          match = set[1].options_for_prop(*args)
          break if match
        }

        return match
      end

      def has_prop?(*args)
        has = nil
        @sets.each {|set|
          has = set[1].has_prop?(*args)
          break if has
        }

        return has
      end
    end
  end
end
