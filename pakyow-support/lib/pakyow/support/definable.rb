# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/deprecatable"
require "pakyow/support/extension"
require "pakyow/support/isolable"
require "pakyow/support/makeable"

require "pakyow/support/definable/registry"
require "pakyow/support/definable/state"

module Pakyow
  module Support
    # Define state for an object.
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     # Create a definable subclass of `Controller`.
    #     #
    #     definable :controller, Controller do
    #       # Optionally extend the subclass with custom behavior.
    #     end
    #   end
    #
    #   # Subclass `Application` to work within a unique namespace.
    #   #
    #   class MyApplication < Application
    #     controller :foo do
    #       # Define custom behavior for the `foo` controller.
    #     end
    #   end
    #
    #   # Access the `foo` controller on the class.
    #   #
    #   MyApplication.controllers.foo.new(...)
    #
    #   # State is also accessible on the instance.
    #   #
    #   MyApplication.new.controllers.foo.new(...)
    #
    #   # State is defined within a logical namespace.
    #   #
    #   MyApplication.controllers.foo.class
    #   => MyApplication::Controllers::Foo
    #
    #   # Keyword arguments are automatically set as class-level instance variables.
    #   #
    #   MyApplication.new(...) do
    #     controller :baz, path: "/baz"
    #   end
    #
    #   MyApplication.controllers.foo.instance_variable_get(:@path)
    #   => "/baz"
    #
    # = State Lookup
    #
    # Definable state can be looked up by name.
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     definable :controller, Controller
    #   end
    #
    #   class MyApplication < Application
    #     controller :foo
    #   end
    #
    #   MyApplication.controller.foo
    #   => MyApplication::Controllers::Foo
    #
    # = Custom Lookups
    #
    # Definable state can be registered with a lookup function for custom lookups.
    #
    # @example
    #   class Controller
    #     attr_reader :path
    #
    #     def initialize(app, path)
    #       @path = path
    #     end
    #
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     definable :controller, Controller, lookup: -> (app, controller, path) {
    #       controller.new(app, path)
    #     }
    #   end
    #
    #   class MyApplication < Application
    #     controller :foo
    #   end
    #
    #   MyApplication.controller.foo("/").path
    #   => "/"
    #
    # = Argument Builder
    #
    # Definable state can be defined with custom arguments by specifying an argument builder.
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     definable :controller, Controller, builder: -> (name, path = "/") {
    #       return name, path: path
    #     }
    #   end
    #
    #   class MyApplication < Application
    #     controller :foo, "/foo"
    #   end
    #
    #   MyApplication.controller.foo.path
    #   => "/foo"
    #
    # = Definable Context
    #
    # By default, isolated objects are defined within the definable object's namespace. This
    # behavior can be changed by specifying a different context using `context`.
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     definable :controller, Controller, context: Object
    #   end
    #
    #   class MyApplication < Application
    #     controller :foo, "/foo"
    #   end
    #
    #   MyApplication.controller.foo
    #   => Foo
    #
    # = Prioritized State
    #
    # By default, defined state is exposed in the order it's defined. In cases where order matters,
    # set the `priority` keyword argument to `:high` or `:low` (defaults to `:default`).
    #
    # @example
    #   class Controller
    #     ...
    #   end
    #
    #   class Application
    #     include Pakyow::Support::Definable
    #
    #     definable :controller, Controller
    #   end
    #
    #   class MyApplication < Application
    #     controller :foo, priority: :low
    #
    #     controller :bar, priority: :high
    #
    #     controller :baz
    #   end
    #
    #   MyApplication.controllers.each.map { |controller|
    #     controller.class
    #   }
    #
    #   => [
    #        MyApplication::Controllers::Bar,
    #        MyApplication::Controllers::Baz,
    #        MyApplication::Controllers::Foo
    #      ]
    #
    module Definable
      extend Extension

      extend_dependency ClassState
      include_dependency Isolable

      using DeepDup

      apply_extension do
        class_state :__definable_registries, default: {}, inheritable: true
      end

      class_methods do
        extend Deprecatable

        # Register a type of state that can be defined by `name`.
        #
        # = Argument Building
        #
        # Definables can use their own argument builder for finalizing the argument list. Argument
        # builders should respond to `call` and return an argument list consisting of a namespace,
        # object name, and any options.
        #
        #   definable :controller, Controller, builder: -> (*namespace, object_name, **options) {
        #     ...
        #
        #     return namespace, object_name, options
        #   }
        #
        # @param state_name [Symbol] the name of the definable state
        # @param definable_object [Object] the object to be defined
        # @param builder [Proc] an optional argument builder
        # @param lookup [Proc] an optional lookup function
        # @param context [Object] the context to define state in
        #
        def definable(state_name, definable_object, builder: nil, lookup: nil, context: isolable_context, &block)
          isolated_object = isolate definable_object, context: context do
            DEFINABLE_OBJECT_EXTENSIONS.each do |extension|
              unless ancestors.include?(extension)
                include extension
              end
            end

            class_eval(&block) if block_given?
          end

          namespace = if context.equal?(isolable_context)
            [Support.inflector.pluralize(state_name.to_s).to_sym]
          else
            []
          end

          state_registry = Registry.new(
            state_name,
            isolated_object,
            parent: self,
            builder: builder,
            lookup: lookup,
            namespace: namespace
          )

          isolated_object.instance_variable_set(:@__defined_state, state_registry)
          __definable_registries[state_name.to_sym] = state_registry

          definition_code = <<~CODE
            def #{state_name}(*namespace, **kwargs, &block)
              registry = __definable_registries[#{state_name.to_sym.inspect}]

              if block_given?
                registry.define(*namespace, **kwargs, &block)
              else
                # Fall back to finding if we aren't defining with a block. This lets us gracefully
                # handle cases where the definable type is pluralized.
                #
                if namespace.any?
                  registry.find(*namespace)
                else
                  registry
                end
              end
            end
          CODE

          lookup_code = <<~CODE
            def #{Support.inflector.pluralize(state_name)}(*namespace)
              registry = __definable_registries[#{state_name.to_sym.inspect}]

              if namespace.any?
                registry.find(*namespace)
              else
                registry
              end
            end
          CODE

          class_eval(lookup_code)
          singleton_class.class_eval(lookup_code)
          singleton_class.class_eval(definition_code)
        end

        # Define the object.
        #
        def define(&block)
          class_eval(&block)
        end

        def state(type)
          __definable_registries[type.to_sym]
        end
        deprecate :state, solution: "all the cooresponding method for `type'"

        # @api private
        DEFINABLE_OBJECT_EXTENSIONS = [
          Makeable, State
        ].freeze

        # @api private
        def inherited(subclass)
          super

          subclass.__definable_registries.each_value do |registry|
            if registry.object.name&.start_with?(name)
              registry.rebase(subclass.isolate(registry.object))
            end

            registry.reparent(subclass)
          end
        end
      end

      prepend_methods do
        # @api private
        def initialize(*, &block)
          @__definable_registries = self.class.__definable_registries.deep_dup
          @__definable_registries.each_value do |registry|
            registry.reparent(self)
          end

          super
        end
      end

      def state(type)
        self.class.state(type)
      end

      # @api private
      attr_reader :__definable_registries
    end
  end
end
