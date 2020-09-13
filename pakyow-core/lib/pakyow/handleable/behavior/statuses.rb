# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Handleable
    module Behavior
      module Statuses
        extend Support::Extension

        common_prepend_methods do
          # Registers a handler that optionally sets the connection status to the value for `as` if
          # a connection is passed as a keyword argument.
          #
          # @example
          #   handle Sequel::NoMatchingRow, as: 404 do
          #     ...
          #   end
          #
          def handle(event = nil, as: nil, &block)
            event = if code = Connection::Statuses.code(event)
              code
            else
              event
            end

            if code = Connection::Statuses.code(as)
              super(event) do |super_event, *args, **kwargs|
                connection = kwargs[:connection]
                connection&.status = code

                if block
                  instance_exec(super_event, *args, **kwargs, &block)
                end

                trigger code, *args, **kwargs
              end
            else
              super(event, &block)
            end
          end

          # Triggers `event`, passing any arguments to triggered handlers.
          #
          # Sets the connection status if `event` is an http status code or name and a connection is
          # passed as a keyword argument.
          #
          def trigger(event, *args, **kwargs)
            connection = kwargs[:connection]

            if code = Connection::Statuses.code(event)
              connection&.status = code
              event = code
            end

            super(event, *args, **kwargs)

            connection&.halt
          end
        end
      end
    end
  end
end
