# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_dup"
require "pakyow/support/extension"

require "pakyow/connection/statuses"

module Pakyow
  module Routing
    module Behavior
      module ErrorHandling
        extend Support::Extension

        prepend_methods do
          # Triggers handlers for `event` in the following order:
          #
          #   * connection handlers
          #   * controller handlers
          #   * application handlers
          #   * environment handlers
          #
          def trigger(event, *args, **kwargs)
            kwargs[:connection] = connection
            connection.trigger(event, *args, **kwargs) do
              super(event, *args, **kwargs) do
                app.trigger(event, *args, **kwargs)
              end
            end
          end
        end
      end
    end
  end
end
