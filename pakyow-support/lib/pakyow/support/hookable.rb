# frozen_string_literal: true

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
    #       performing "swim" do
    #         puts "swimming"
    #       end
    #     end
    #   end
    #
    #   Fish.before "swim" do
    #     puts "prepping"
    #   end
    #
    #   fish = Fish.new
    #
    #   fish.after "swim" do
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
      PRIORITIES = { default: 0, high: 1, low: -1 }.freeze

      def self.included(base)
        base.include CommonMethods
        base.include InstanceMethods

        base.extend ClassMethods

        base.extend ClassState
        base.class_state :__events, default: [], inheritable: true, getter: false
        base.class_state :__hooks, default: [], inheritable: true, getter: false
        base.class_state :__hook_hash, default: { after: {}, before: {} }, inheritable: true
        base.class_state :__hook_pipeline, default: { after: {}, before: {} }, inheritable: true
      end

      # @api private
      def known_event?(event)
        self.class.known_event?(event.to_sym)
      end

      # Class-level api methods.
      #
      module ClassMethods
        attr_reader :__hook_pipeline

        def self.extended(base)
          base.extend(CommonMethods)
        end

        # Sets the known events for the hookable object. Hooks registered for
        # an event that doesn't exist will raise an ArgumentError.
        #
        # @param events [Array<Symbol>] The list of known events.
        #
        def events(*events)
          @__events.concat(events.map(&:to_sym)).uniq!; @__events
        end

        # Defines a hook to call before event occurs.
        #
        # @param event [Symbol] The name of the event.
        # @param priority [Symbol, Integer] The priority of the hook.
        #   Other priorities include:
        #     high (1)
        #     low (-1)
        #
        def before(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:before, event, name, priority, exec, block)
        end
        alias on before

        # Defines a hook to call after event occurs.
        #
        # @see #before
        #
        def after(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:after, event, name, priority, exec, block)
        end

        # Defines a hook to call before and after event occurs.
        #
        # @see #before
        #
        def around(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:before, event, name, priority, exec, block)
          add_hook(:after, event, name, priority, exec, block)
        end

        # @api private
        def known_event?(event)
          @__events.include?(event.to_sym)
        end

        def known_hook?(event)
          @__hooks.any? { |hook|
            hook[:name] == event.to_sym
          }
        end
      end

      # Methods included at the class and instance level.
      #
      module CommonMethods
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
          hooks(type, event).each do |hook|
            if hook[:exec]
              instance_exec(*args, &hook[:block])
            else
              hook[:block].call(*args)
            end
          end
        end

        # @api private
        def hooks(type, event)
          __hook_pipeline[type][event] || []
        end

        # @api private
        def add_hook(type, event, name, priority, exec, hook)
          if priority.is_a?(Symbol)
            priority = PRIORITIES[priority]
          end

          if known_event?(event) || known_hook?(event)
            hook = {
              type: type,
              event: event.to_sym,
              name: name ? name.to_sym : nil,
              priority: priority,
              block: hook,
              exec: exec
            }

            (@__hook_hash[type.to_sym][event.to_sym] ||= []) << hook
            @__hooks << hook
          else
            raise ArgumentError, "#{event} is not a known hook event"
          end

          reprioritize!(type, event)
          pipeline!(type, event)

          if known_hook?(event)
            traverse_events_for_hook(event) do |hook_event|
              pipeline!(:before, hook_event); pipeline!(:after, hook_event)
            end
          end
        end

        # @api private
        def traverse_events_for_hook(name, &block)
          if hook = @__hooks.find { |h| h[:name] == name.to_sym }
            yield hook[:event]
            traverse_events_for_hook(hook[:event], &block)
          end
        end

        # @api private
        def reprioritize!(type, event)
          @__hook_hash[type.to_sym][event.to_sym] = @__hook_hash[type.to_sym][event.to_sym].group_by { |hook|
            hook[:priority]
          }.sort { |a, b|
            b[0] <=> a[0]
          }.flat_map { |group|
            group[1]
          }
        end

        # @api private
        def pipeline!(type, event)
          __hook_pipeline[type.to_sym][event.to_sym] = @__hook_hash.dig(type.to_sym, event.to_sym).to_a.flat_map { |hook|
            [@__hook_pipeline[:before][hook[:name]].to_a, hook, @__hook_pipeline[:after][hook[:name]].to_a].flatten
          }
        end
      end

      module InstanceMethods
        # @api private
        def __hook_pipeline
          self.class.__hook_pipeline
        end
      end
    end
  end
end
