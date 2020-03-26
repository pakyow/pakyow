# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/extension"

require "pakyow/support/handleable/event"
require "pakyow/support/handleable/pipeline"

module Pakyow
  module Support
    # Makes an object able to handle events, such as errors.
    #
    module Handleable
      extend Extension

      extend_dependency ClassState

      apply_extension do
        class_state :__handlers, default: {
          default: Class.new(Pipeline).tap do |pipeline|
            pipeline.action do |event|
              if event.object.is_a?(Exception)
                raise event
              end
            end
          end
        }, inheritable: true
      end

      prepend_methods do
        def initialize(*)
          @__handlers = self.class.__handlers.dup

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
          (@__handlers[event || :global] ||= Pipeline.new).action(&block)
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
        def trigger(event, *args, **kwargs)
          resolve_handler_for_event(event).__pipeline.rcall(self, Event.new(event), *args, **kwargs); self
        end

        private def resolve_handler_for_event(event)
          handler = case event
          when Exception
            @__handlers.find { |handler_event, handler|
              handler_event.is_a?(Class) && event.is_a?(handler_event)
            }&.at(1)
          else
            @__handlers[event]
          end

          handler || @__handlers[:global] || @__handlers[:default]
        end
      end
    end
  end
end
