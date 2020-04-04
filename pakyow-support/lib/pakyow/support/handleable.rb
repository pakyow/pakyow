# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/extension"
require "pakyow/support/hookable"

require "pakyow/support/handleable/pipeline"

module Pakyow
  module Support
    # Makes an object able to handle events, such as errors.
    #
    module Handleable
      # @api private
      module Hooks
        extend Extension

        apply_extension do
          events :handle
        end

        common_prepend_methods do
          private def call_handler(handler, event, context, *args, **kwargs)
            performing :handle, event, *args, **kwargs do
              super
            end
          end
        end
      end

      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__handlers, default: {}, inheritable: true
        class_state :__handler_events, default: [], inheritable: true

        if ancestors.include?(Hookable)
          include Hooks
        end
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
          if handler = find_handler(event)
            handler.__pipeline.rcall(self, event, *args, **kwargs)
          elsif block_given?
            yield
          elsif event.is_a?(Exception)
            raise event
          end

          self
        end

        private def find_handler(event)
          case event
          when Exception
            @__handler_events.each do |handler_event|
              if handler_event == :global || (handler_event.is_a?(Class) && event.is_a?(handler_event))
                return @__handlers[handler_event]
              end
            end
          else
            return @__handlers[event] || @__handlers[:global]
          end

          nil
        end
      end
    end
  end
end
