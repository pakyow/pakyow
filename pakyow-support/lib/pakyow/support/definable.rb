# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/inflector"
require "pakyow/support/makeable"

module Pakyow
  module Support
    # Provides control over how state is defined on an object, and how state is
    # shared across object instances and subclasses.
    #
    # You define the type of state provided by an object, along with any global
    # state for that object type. When an instance is created or the definable
    # object is subclassed, the new object inherits the global state and can be
    # extended with its own state. Definable objects' `initialize` method should
    # always call super with the block to ensure that state is inherited correctly.
    #
    # Once `defined!` is called on an instance, consider freezing the object so
    # that it cannot be extended later.
    #
    #
    # @example
    #   class SomeDefinableObject
    #     include Support::Definable
    #
    #     def initialize(some_arg, &block)
    #       super()

    #       # Do something with some_arg, etc.
    #
    #       defined!(&block)
    #     end
    #   end
    #
    # @api private
    #
    module Definable
      using DeepDup

      def self.included(base)
        base.include CommonMethods
        base.extend ClassMethods, CommonMethods
        base.prepend Initializer
        base.extend Support::Makeable
        base.instance_variable_set(:@__state, {})
      end

      # @api private
      def defined!(&block)
        # set instance level state
        self.instance_eval(&block) if block_given?

        # merge global state
        @__state.each do |name, state|
          state.instances.concat(self.class.__state[name].instances)
        end

        # merge inherited state
        if inherited = self.class.__inherited_state
          @__state.each do |name, state|
            instances = state.instances
            instances.concat(inherited[name].instances) if inherited[name]
          end
        end
      end

      module ClassMethods
        attr_reader :__state, :__inherited_state

        def inherited(subclass)
          super

          subclass.instance_variable_set(:@__inherited_state, @__state.deep_dup)
          subclass.instance_variable_set(:@__state, @__state.each_with_object({}) { |(name, state_instance), state|
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
        #
        def stateful(name, object)
          name = name.to_sym
          @__state[name] = State.new(name, object)
          plural_name = Support.inflector.pluralize(name.to_s).to_sym

          within = if __class_name
            ClassNamespace.new(*__class_name.namespace.parts.dup.concat([plural_name]))
          else
            self
          end

          method_body = Proc.new do |*args, priority: :default, **opts, &block|
            return @__state[name] if block.nil?

            object.make(*args, within: within, **opts, &block).tap do |state|
              @__state[name].register(state, priority: priority)
            end
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

      module CommonMethods
        # Returns registered state instances. If +type+ is passed, returns state of that type.
        #
        def state(type = nil)
          if instance_variable_defined?(:@__state)
            return @__state if type.nil?

            if @__state && @__state.key?(type)
              @__state[type].instances
            else
              []
            end
          else
            {}
          end
        end
      end

      module Initializer
        def initialize(*)
          # Create mutable state for this instance based on global.
          #
          @__state = self.class.__state.each_with_object({}) { |(name, global_state), state|
            state[name] = State.new(name, global_state.object)
          }

          super
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

        unless instance.is_a?(Module)
          enforce_registration!(instance)
        end

        instances << instance

        priorities[instance] = priority
        reprioritize!
      end

      def enforce_registration!(instance)
        ancestors = if instance.respond_to?(:new)
          instance.ancestors
        else
          instance.class.ancestors
        end

        unless ancestors.include?(@object)
          raise ArgumentError, "Expected instance of '#{@object}'"
        end
      end

      def reprioritize!
        @instances.sort! { |a, b|
          (@priorities[b] || 0) <=> (@priorities[a] || 0)
        }
      end
    end
  end
end
