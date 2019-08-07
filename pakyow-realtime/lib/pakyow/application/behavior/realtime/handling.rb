# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Application
    module Behavior
      module Realtime
        # Handles incoming websocket messages.
        #
        module Handling
          extend Support::Extension

          apply_extension do
            class_state :__websocket_handlers, default: {}
          end

          class_methods do
            def handle_websocket_message(type, &block)
              (@__websocket_handlers[type.to_s] ||= []) << block
            end
          end
        end
      end
    end
  end
end
