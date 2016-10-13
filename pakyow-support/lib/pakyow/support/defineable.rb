require "pakyow/support/deep_dup"

module Pakyow
  module Support
    # Provides control over how state is defined on an object, and how state is
    # shared across object instances and subclasses.
    #
    # You define the type of state provided by an object, along with any global
    # state for that object type. When an instance is created or the definable
    # object is subclassed, the new object inherits the global state and can be
    # extended with its own state.
    #
    # Once an instance has been created, global state for that object is frozen.
    #
    module Defineable
      def self.included(base)
        base.extend ClassAPI
      end

      # @api private
      attr_reader :state

      def initialize
        # global state is now immutable
        self.class.freeze

        # mutable state for this instance
        @state = self.class.state.dup
      end

      # @api private
      # TODO: don't use method missing and just define the methods instead
      def method_missing(name)
        @state.fetch(name) {
          raise ArgumentError, "Unknown state '#{name}'"
        }
      end

      module ClassAPI
        attr_reader :state

        def inherited(subclass)
          subclass.instance_variable_set(:@state, Utils::Dup.deep(state))
        end

        # @api private
        def freeze
          @state.each { |_, state| state.freeze }
          @state.freeze
          super
        end

        # Register a type of state that can be defined.
        #
        def stateful(name, object)
          name = name.to_sym

          (@state ||= {})[name] = State.new(name, object)
          define_singleton_method name do |*args, &state|
            instance = object.new(*args)
            instance.instance_eval(&state)
            @state[name] << instance
          end
        end

        # Define state for the object.
        #
        def define(&block)
          # instead of this evaling now, what if it deferred?
          instance_eval(&block)
        end
      end
    end

    # Contains state for a definable class or instance.
    #
    # @api private
    class State
      attr_reader :name, :object, :instances

      def initialize(name, object)
        @name = name.to_sym
        @object = object
        @instances = []
      end

      def initialize_copy(original)
        super
        @instances = Utils::Dup.deep(original.instances)
      end

      def <<(instance)
        unless instance.class.ancestors.include?(object)
          raise ArgumentError, "Expected instance of '#{object}'"
        end

        instances << instance
      end

      def freeze
        instances.each(&:freeze)
        instances.freeze
        super
      end
    end
  end
end
