# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/extension"

require "pakyow/support/handleable/pipeline"

module Pakyow
  module Support
    # Makes an object able to handle events, such as errors.
    #
    module Handleable
      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__handlers, default: {}, inheritable: true
        class_state :__handler_events, default: [], inheritable: true
      end

      prepend_methods do
        def initialize(*)
          @__handlers = self.class.__handlers.dup
          @__handler_events = self.class.__handler_events.dup

          super
        end
      end

      common_methods do
        # Register a handler for `event`. When triggered, the block will be called.
        #
        # The `event` can be a type of exception, or any other object. For exceptions, the handler
        # will be called when triggered for the exception or its subclass.
        #
        def handle(event = nil, &block)
          event = event || :global

          unless handler = @__handlers[event]
            handler = @__handlers[event] = Pipeline.new
            @__handler_events.unshift(event)
          end

          handler.action(&block)
        end

        # Yields a context where exceptions automatically trigger handlers.
        #
        # Any keyword arguments will be passed through as arguments to the triggered handlers.
        #
        def handling(**kwargs)
          yield
        rescue => error
          trigger(error, **kwargs)
        end

        # Triggers `event`, passing any arguments to triggered handlers.
        #
        def trigger(event, *args, **kwargs, &block)
          call_each_handler_for_event(event, self, *args, **kwargs, &block); self
        end

        private def call_each_handler_for_event(event, context, *args, **kwargs)
          case event
          when Exception
            handled = false

            @__handler_events.each do |handler_event|
              if handler_event == :global || (handler_event.is_a?(Class) && event.is_a?(handler_event))
                handled = true; call_handler(@__handlers[handler_event], event, context, *args, **kwargs)
              end
            end

            unless handled || block_given?
              raise event
            end
          else
            if handler = @__handlers[event] || @__handlers[:global]
              call_handler(handler, event, context, *args, **kwargs)
            end
          end

          yield if block_given?
        end

        private def call_handler(handler, event, context, *args, **kwargs)
          handler.__pipeline.rcall(context, event, *args, **kwargs)
        end
      end
    end
  end
end
