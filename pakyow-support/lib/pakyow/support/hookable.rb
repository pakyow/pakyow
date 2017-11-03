require "pakyow/support/deep_dup"

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
    #     known_events :swim
    #
    #     def swim
    #       puts "swimming"
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
        base.extend ClassAPI
        base.prepend Initializer

        base.instance_variable_set(:@hook_hash, { after: {}, before: {} })
        base.instance_variable_set(:@pipeline, { after: {}, before: {} })
      end

      # @api private
      def known_event?(event)
        self.class.known_event?(event.to_sym)
      end

      module Initializer
        def initialize(*)
          @hook_hash = self.class.hook_hash.deep_dup
          @pipeline = self.class.pipeline.deep_dup

          super
        end
      end

      # Class-level api methods.
      #
      module ClassAPI
        def self.extended(base)
          base.extend(API)
        end

        def inherited(subclass)
          super

          subclass.instance_variable_set(:@known_events, @known_events)
          subclass.instance_variable_set(:@hook_hash, @hook_hash)
          subclass.instance_variable_set(:@pipeline, @pipeline)
        end

        # Sets the known events for the hookable object. Hooks registered for
        # an event that doesn't exist will raise an ArgumentError.
        #
        # @param events [Array<Symbol>] The list of known events.
        #
        def known_events(*events)
          (@known_events ||= []).concat(events.map(&:to_sym)).uniq!; @known_events
        end

        # @api private
        def known_event?(event)
          @known_events && @known_events.include?(event.to_sym)
        end
      end

      # Methods included at the class and instance level.
      #
      module API
        attr_reader :hook_hash, :pipeline

        # Defines a hook to call before event occurs.
        #
        # @param event [Symbol] The name of the event.
        # @param priority [Symbol, Integer] The priority of the hook.
        #   Other priorities include:
        #     high (1)
        #     low (-1)
        #
        def before(event, priority: PRIORITIES[:default], &block)
          add_hook(hook_hash, :before, event, priority, block)
        end

        # Defines a hook to call after event occurs.
        #
        # @see #before
        #
        def after(event, priority: PRIORITIES[:default], &block)
          add_hook(hook_hash, :after, event, priority, block)
        end

        # Defines a hook to call before and after event occurs.
        #
        # @see #before
        #
        def around(event, priority: PRIORITIES[:default], &block)
          add_hook(hook_hash, :before, event, priority, block)
          add_hook(hook_hash, :after, event, priority, block)
        end

        # Calls all registered hooks for `event`, yielding between them.
        #
        # @param event [Symbol] The name of the event.
        #
        def hook_around(event)
          call_hooks :before, event
          value = yield
          call_hooks :after, event
          value
        end

        # Calls all registered hooks of type, for event.
        #
        # @param type [Symbol] The type of event (e.g. before / after).
        # @param event [Symbol] The name of the event.
        #
        def call_hooks(type, event)
          hooks(type, event).each do |hook|
            if hook.arity == 0
              instance_exec(&hook)
            else
              hook.call(self)
            end
          end
        end

        # @api private
        def hooks(type, event)
          pipeline[type][event] || []
        end

        # @api private
        def add_hook(hash_of_hooks, type, event, priority, hook)
          raise ArgumentError, "#{event} is not a known hook event" unless known_event?(event)
          priority = PRIORITIES[priority] if priority.is_a?(Symbol)
          (hash_of_hooks[type.to_sym][event.to_sym] ||= []) << [priority, hook]

          reprioritize!(hash_of_hooks, type, event)
          pipeline!(hash_of_hooks, type, event)
        end

        # @api private
        def reprioritize!(hash_of_hooks, type, event)
          hash_of_hooks[type.to_sym][event.to_sym].sort! { |a, b| b[0] <=> a[0] }
        end

        # @api private
        def pipeline!(hash_of_hooks, type, event)
          pipeline[type.to_sym][event.to_sym] = hash_of_hooks[type.to_sym][event.to_sym].map { |t| t[1] }
        end
      end
    end
  end
end
