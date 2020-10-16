# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Handleable
    module Behavior
      module Defaults
        module ServerError
          extend Support::Extension

          apply_extension do
            # The default 500 handler. Prefer overriding this instead of the top-level error handler.
            #
            handle 500 do |event, connection:|
              connection.headers.clear
              connection.body = StringIO.new("500 Server Error")
              connection.halt
            end
          end
        end
      end
    end
  end
end
