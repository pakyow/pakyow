# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Connection
    module Behavior
      module Handling
        extend Support::Extension

        require "pakyow/handleable/behavior/statuses"
        include_dependency Handleable::Behavior::Statuses

        prepend_methods do
          # Adds the connection to the triggered keyword arguments.
          #
          def trigger(event, *args, **kwargs)
            super(event, *args, connection: self, **kwargs)
          end
        end
      end
    end
  end
end
