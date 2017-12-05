# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/deep_freeze"

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
    # Definable objects' `initialize` method should always call super with
    # the block to ensure that state is inherited correctly.
    #
    # @example
    #   class SomeDefinableObject
    #     include Support::Definable
    #
    #     def initialize(some_arg, &block)
    #       # Do something with some_arg, etc.
    #
    #       super(&block)
    #     end
    #   end
    #
    module Definable
      using DeepDup
      using DeepFreeze

      def self.included(base)
        base.extend ClassAPI
        base.instance_variable_set(:@state, {})
      end

      # @api private
      attr_reader :state

      # @api private
      def defined!(&block)
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
            instances = state.instances
            instances.concat(inherited[name].instances) if inherited[name]
          end
        end

        # instance state is now immutable
        deep_freeze
      end

      # Returns register instances for state.
      #
      def state_for(type)
        return [] unless @state.key?(type)
        @state[type].instances
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
        # @param object
        #   Can be a class or instance, but must respond to :make. The `make`
        #   method should return the object to be "made" and accept a block
        #   that should be evaluated in the context of the object.
        #
        #     class Person
        #       # ...
        #
        #       def make(name, dob, &block)
        #         person = self.class.new(name, dob)
        #
        #         person.instance_eval(&block)
        #         person
        #       end
        #
        #       def befriend(person)
        #         friends << person
        #       end
        #     end
        #
        #     class App
        #       include Pakyow::Support::Definable
        #
        #       stateful :person, Person
        #     end
        #
        #     john = App.person 'John', Date.new(1988, 8, 13) do
        #     end
        #
        #     App.person 'Sofie', Date.new(2015, 9, 6) do
        #       befriend(john)
        #     end
        def stateful(name, object)
          name = name.to_sym
          @state[name] = State.new(name, object)
          method_body = Proc.new do |*args, priority: :default, **opts, &block|
            return @state[name] if block.nil?

            state = object.make(*args, within: self, **opts, &block)
            @state[name].register(state, priority: priority)
            state
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

      attr_reader :name, :object, :instances, :priorities

      PRIORITIES = { default: 0, high: 1, low: -1 }.freeze

      def initialize(name, object)
        @name = name.to_sym
        @object = object
        @instances = []
        @priorities = {}
      end

      def initialize_copy(original)
        super
        @instances = original.instances.deep_dup
      end

      # TODO: we handle both instances and classes, so reconsider the variable naming
      def <<(instance)
        register(instance)
      end

      # TODO: we handle both instances and classes, so reconsider the variable naming
      def register(instance, priority: :default)
        unless priority.is_a?(Integer)
          priority = PRIORITIES.fetch(priority) {
            raise ArgumentError, "Unknown priority `#{priority}'"
          }
        end

        ancestors = if instance.respond_to?(:new)
          instance.ancestors
        else
          instance.class.ancestors
        end

        unless ancestors.include?(object)
          raise ArgumentError, "Expected instance of '#{object}'"
        end

        instances << instance

        priorities[instance] = priority
        reprioritize!
      end

      def reprioritize!
        @instances.sort! { |a, b|
          priorities[b] <=> priorities[a]
        }
      end
    end
  end
end
