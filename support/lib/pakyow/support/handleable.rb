# frozen_string_literal: true

require_relative "class_state"
require_relative "extension"
require_relative "hookable"

require_relative "handleable/pipeline"

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
        if System.ruby_version < "2.7.0"
          def initialize(*)
            __common_handleable_initialize
            super
          end
        else
          def initialize(*, **)
            __common_handleable_initialize
            super
          end
        end

        private def __common_handleable_initialize
          @__handlers = self.class.__handlers.dup
          @__handler_events = self.class.__handler_events.dup
        end
      end

      common_methods do
        # Register a handler for `event`. When triggered, the block will be called.
        #
        # The `event` can be a type of exception, or any other object. For exceptions, the handler
        # will be called when triggered for the exception or its subclass.
        #
        def handle(event = nil, &block)
          event ||= :global

          unless (handler = @__handlers[event])
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
        rescue Exception => error
          trigger(error, **kwargs)
        end

        # Triggers `event`, passing any arguments to triggered handlers.
        #
        def trigger(event, *args, **kwargs, &block)
          if (handler = find_handler(event))
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
