# frozen_string_literal: true

require_relative "class_state"
require_relative "extension"
require_relative "system"

module Pakyow
  module Support
    # Makes an object hookable, as well as its subclasses. Hookable objects define and perform one
    # or more event. Other objects can define behavior to be called before or after an event.
    #
    # Hooks can be defined at the class or instance level. By default, hooks are called in the order
    # they are defined. Each hook is assigned a priority to influence when it is called relative to
    # other hooks of the same type. Default hook priority is `0`, and can be set to `1` (high),
    # `-1` (low), or any positive or negative integer.
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
      extend Extension

      # Known hook priorities.
      #
      PRIORITIES = {default: 0, high: 1, low: -1}.freeze

      extend_dependency ClassState

      apply_extension do
        class_state :__events, default: [], inheritable: true, reader: false
        class_state :__hooks, default: [], inheritable: true, reader: false
        class_state :__hook_hash, default: {after: {}, before: {}}, inheritable: true
        class_state :__hook_pipeline, default: {after: {}, before: {}}, inheritable: true
      end

      class_methods do
        # Defines available events. Note that attempting to register a hook for an event that
        # doesn't exist will result in an `ArgumentError`.
        #
        # @param events [Array<Symbol>] List of events.
        #
        def events(*events)
          @__events.concat(events.map(&:to_sym)).uniq!
          @__events
        end

        # Defines a hook to call before `event` occurs. If the hook is named it becomes an event
        # that future hooks can be defined for.
        #
        # @param event [Symbol] The name of the event.
        # @param name [Symbol] The name of the hook.
        # @param priority [Symbol, Integer] The priority of the hook.
        # @param exec [Boolean] If true, the hook will be called in context of the hookable object.
        #
        def before(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:before, event, name, priority, exec, block)
        end
        alias_method :on, :before

        # Defines a hook to call after `event` occurs.
        #
        # @see #before
        #
        def after(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:after, event, name, priority, exec, block)
        end

        # Defines a hook to call before and after `event` occurs.
        #
        # @see #before
        #
        def around(event, name = nil, priority: PRIORITIES[:default], exec: true, &block)
          add_hook(:before, event, name, priority, exec, block)
          add_hook(:after, event, name, priority, exec, block)
        end

        private def known_event?(event)
          @__events.include?(event.to_sym)
        end

        private def known_hook?(event)
          @__hooks.any? { |hook|
            hook[:name] == event.to_sym
          }
        end
      end

      common_methods do
        # Calls all registered hooks for `event`, yielding between them.
        #
        # @param event [Symbol] The name of the event.
        #
        def performing(event, *args, **kwargs)
          call_hooks(:before, event, *args, **kwargs)
          value = yield
          call_hooks(:after, event, *args, **kwargs)
          value
        end

        # Calls all registered hooks of type, for event.
        #
        # @param type [Symbol] The type of event (e.g. before / after).
        # @param event [Symbol] The name of the event.
        #
        def call_hooks(type, event, *args, **kwargs)
          hooks(type, event).each do |hook|
            if hook[:exec]
              instance_exec(*args, **kwargs, &hook[:block])
            else
              hook[:block].call(*args, **kwargs)
            end
          end
        end

        # @api private
        def each_hook(type, event, &block)
          return enum_for(:each_hook, type, event) unless block_given?

          hooks(type, event).each(&block)
        end

        private def hooks(type, event)
          __hook_pipeline[type][event] || []
        end

        private def add_hook(type, event, name, priority, exec, hook)
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
              pipeline!(:before, hook_event)
              pipeline!(:after, hook_event)
            end
          end
        end

        private def traverse_events_for_hook(name, &block)
          if (hook = @__hooks.find { |h| h[:name] == name.to_sym })
            yield hook[:event]
            traverse_events_for_hook(hook[:event], &block)
          end
        end

        private def reprioritize!(type, event)
          @__hook_hash[type.to_sym][event.to_sym] = @__hook_hash[type.to_sym][event.to_sym].group_by { |hook|
            hook[:priority]
          }.sort { |a, b|
            b[0] <=> a[0]
          }.flat_map { |group|
            group[1]
          }
        end

        private def pipeline!(type, event)
          __hook_pipeline[type.to_sym][event.to_sym] = @__hook_hash.dig(type.to_sym, event.to_sym).to_a.flat_map { |hook|
            [@__hook_pipeline[:before][hook[:name]].to_a, hook, @__hook_pipeline[:after][hook[:name]].to_a].flatten
          }
        end
      end

      private def known_event?(event)
        self.class.known_event?(event.to_sym)
      end

      private def __hook_pipeline
        self.class.__hook_pipeline
      end
    end
  end
end
