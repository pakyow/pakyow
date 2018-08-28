# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/class_state"

module Pakyow
  module Support
    # Makes it possible to define and call hooks on an object.
    #
    # Hooks can be defined at the class or instance level. When calling hooks
    # on an instance, hooks defined on the class will be called first.
    #
    # By default, hooks are called in the order they are defined. Each hook
    # can be assigned a relative priority to influence when it is to be called
    # (relative to other hooks of the same type). Default hook priority is `0`,
    # and can instead be set to `1` (high) or `-1` (low).
    #
    # @example
    #   class Fish
    #     include Pakyow::Support::Hookable
    #     events :swim
    #
    #     def swim
    #       performing :swim do
    #         puts "swimming"
    #       end
    #     end
    #   end
    #
    #   Fish.before :swim do
    #     puts "prepping"
    #   end
    #
    #   fish = Fish.new
    #
    #   fish.after :swim do
    #     puts "resting"
    #   end
    #
    #   fish.swim
    #   => prepping
    #      swimming
    #      resting
    #
    module Hookable
      # Known hook priorities.
      #
      PRIORITIES = { default: 0, high: 1, low: -1 }

      using DeepDup

      def self.included(base)
        base.include API
        base.extend ClassMethods
        base.prepend Initializer

        base.extend ClassState
        base.class_state :__events, default: [], inheritable: true, getter: false
        base.class_state :__hook_hash, default: { after: {}, before: {} }, inheritable: true
        base.class_state :__hook_pipeline, default: { after: {}, before: {} }, inheritable: true
      end

      # @api private
      def known_event?(event)
        self.class.known_event?(event.to_sym)
      end

      module Initializer
        def initialize(*)
          @__hook_hash = self.class.__hook_hash.deep_dup
          @__hook_pipeline = self.class.__hook_pipeline.deep_dup

          super
        end
      end

      # Class-level api methods.
      #
      module ClassMethods
        def self.extended(base)
          base.extend(API)
        end

        # Sets the known events for the hookable object. Hooks registered for
        # an event that doesn't exist will raise an ArgumentError.
        #
        # @param events [Array<Symbol>] The list of known events.
        #
        def events(*events)
          @__events.concat(events.map(&:to_sym)).uniq!; @__events
        end

        # @api private
        def known_event?(event)
          @__events.include?(event.to_sym)
        end
      end

      # Methods included at the class and instance level.
      #
      module API
        attr_reader :__hook_hash, :__hook_pipeline

        # Defines a hook to call before event occurs.
        #
        # @param event [Symbol] The name of the event.
        # @param priority [Symbol, Integer] The priority of the hook.
        #   Other priorities include:
        #     high (1)
        #     low (-1)
        #
        def before(event, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(@__hook_hash, :before, event, priority, exec, block)
        end
        alias on before

        # Defines a hook to call after event occurs.
        #
        # @see #before
        #
        def after(event, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(@__hook_hash, :after, event, priority, exec, block)
        end

        # Defines a hook to call before and after event occurs.
        #
        # @see #before
        #
        def around(event, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(@__hook_hash, :before, event, priority, exec, block)
          add_hook(@__hook_hash, :after, event, priority, exec, block)
        end

        # Calls all registered hooks for `event`, yielding between them.
        #
        # @param event [Symbol] The name of the event.
        #
        def performing(event, *args)
          call_hooks(:before, event, *args)
          value = yield
          call_hooks(:after, event, *args)
          value
        end

        # Calls all registered hooks of type, for event.
        #
        # @param type [Symbol] The type of event (e.g. before / after).
        # @param event [Symbol] The name of the event.
        #
        def call_hooks(type, event, *args)
          hooks(type, event).each do |hook, should_exec|
            if should_exec
              instance_exec(*args, &hook)
            else
              hook.call(*args)
            end
          end
        end

        # @api private
        def hooks(type, event)
          @__hook_pipeline[type][event] || []
        end

        # @api private
        def add_hook(hash_of_hooks, type, event, priority, exec, hook)
          raise ArgumentError, "#{event} is not a known hook event" unless known_event?(event)
          priority = PRIORITIES[priority] if priority.is_a?(Symbol)
          (hash_of_hooks[type.to_sym][event.to_sym] ||= []) << [priority, hook, exec]

          reprioritize!(hash_of_hooks, type, event)
          pipeline!(hash_of_hooks, type, event)
        end

        # @api private
        def reprioritize!(hash_of_hooks, type, event)
          hash_of_hooks[type.to_sym][event.to_sym].sort! { |a, b| b[0] <=> a[0] }
        end

        # @api private
        def pipeline!(hash_of_hooks, type, event)
          @__hook_pipeline[type.to_sym][event.to_sym] = hash_of_hooks[type.to_sym][event.to_sym].map { |t| t[1..2] }
        end
      end
    end
  end
end
