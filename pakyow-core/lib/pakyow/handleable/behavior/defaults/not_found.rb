# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Handleable
    module Behavior
      module Defaults
        module NotFound
          extend Support::Extension

          apply_extension do
            # The default 404 handler. Override this for custom 404 handling.
            #
            handle 404 do |event, connection:|
              connection.headers.clear
              connection.body = StringIO.new("404 Not Found")
              connection.halt
            end
          end
        end
      end
    end
  end
end
