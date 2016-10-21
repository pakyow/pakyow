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
      using DeepDup

      def self.included(base)
        base.extend ClassAPI
      end

      # @api private
      attr_reader :state

      def initialize(&block)
        # create mutable state for this instance based on global
        @state = self.class.state.each_with_object({}) { |(name, global_state), state|
          state[name] = State.new(name, global_state.object)
        }

        # set instance level state
        self.instance_eval(&block) if block_given?

        # merge global state
        @state.each do |name, state|
          state.instances.concat(self.class.state[name].instances)
        end

        # merge inherited state
        if inherited = self.class.inherited_state
          @state.each do |name, state|
            state.instances.concat(inherited[name].instances)
          end
        end

        # instance state is now immutable
        freeze
      end

      # Returns register instances for state.
      #
      def state_for(type)
        return [] unless @state.key?(type)
        @state[type].instances
      end

      # @api private
      def freeze
        @state.each { |_, state| state.freeze }
        @state.freeze
        super
      end

      module ClassAPI
        attr_reader :state, :inherited_state

        def inherited(subclass)
          super

          subclass.instance_variable_set(:@inherited_state, state.deep_dup)
          subclass.instance_variable_set(:@state, state.each_with_object({}) { |(name, state_instance), state|
            state[name] = State.new(name, state_instance.object)
          })
        end

        # Register a type of state that can be defined.
        #
        def stateful(name, object)
          name = name.to_sym
          (@state ||= {})[name] = State.new(name, object)
          method_body = Proc.new do |*args, &block|
            return @state[name] if block.nil?
            instance = object.new(*args)
            instance.instance_eval(&block)
            @state[name] << instance
          end

          define_method name, &method_body
          define_singleton_method name, &method_body
        end

        # Define state for the object.
        #
        def define(&block)
          instance_eval(&block)
        end
      end
    end

    # Contains state for a definable class or instance.
    #
    # @api private
    class State
      using DeepDup

      attr_reader :name, :object, :instances

      def initialize(name, object)
        @name = name.to_sym
        @object = object
        @instances = []
      end

      def initialize_copy(original)
        super
        @instances = original.instances.deep_dup
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
