require 'singleton'

module Pakyow
  module Presenter
    # A singleton that manages BinderSet instances for an app. It handles
    # the creation / registration of sets and provides a mechanism
    # to augment data to be bound with values from the sets.
    #
    class Binder
      include Singleton

      # Access to the registered binder sets for an app.
      #
      attr_reader :sets

      def initialize
        @sets = {}
      end

      # Resets the registered binder sets.
      #
      # @return [Binder] the reset instance
      #
      def reset
        @sets = {}
        self
      end

      # Creates and registers a new binder set by name. A block should be passed
      # that defines the bindings. This block will be evaluated in context
      # of the created binder set.
      #
      # @see BinderSet
      #
      # @param name [Symbol] the name of the binder set to be created
      #
      def set(name, &block)
        @sets[name] = BinderSet.new(&block)
      end

      # Returns the value for the scope->prop by applying any defined bindings to the data.
      #
      # @param scope [Symbol] the scope name
      # @param prop [Symbol] the prop name
      # @param bindable [Symbol] the data being bound
      # @param bindings [Symbol] additional bindings to take into consideration when determining the value
      # @param context [Symbol] context passed through to the defined bindings
      #
      def value_for_scoped_prop(scope, prop, bindable, bindings, context)
        if @sets.empty?
          binding_fn = bindings[prop]
        else
          binding_fn = @sets.lazy.map { |set|
            set[1].match_for_prop(prop, scope, bindable, bindings)
          }.find { |match|
            !match.nil?
          }
        end

        if binding_fn
          binding_eval = BindingEval.new(prop, bindable, context)
          binding_eval.eval(&binding_fn)
        else # default value
          if bindable.is_a?(Hash)
            bindable.fetch(prop) { bindable[prop.to_s] }
          elsif bindable.class.method_defined?(prop)
            bindable.send(prop)
          end
        end
      end

      # Returns true if a binding is defined for the scope->prop.
      #
      def has_scoped_prop?(scope, prop, bindings)
        @sets.lazy.map { |set|
          set[1].has_prop?(scope, prop, bindings)
        }.find { |has_prop|
          has_prop
        }
      end

      # Returns options for the scope->prop.
      #
      def options_for_scoped_prop(scope, prop, bindable, context)
        @sets.lazy.map { |set|
          set[1].options_for_prop(scope, prop, bindable, context)
        }.find { |options|
          !options.nil?
        }
      end

      def bindings_for_scope(scope, bindings = {})
        return bindings if @sets.empty?

        @sets.map { |set|
          set[1].bindings_for_scope(scope, bindings)
        }.inject({}) { |acc, bindings|
          acc.merge(bindings)
        }
      end
    end
  end
end
