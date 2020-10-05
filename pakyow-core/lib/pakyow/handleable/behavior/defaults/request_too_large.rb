# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Handleable
    module Behavior
      module Defaults
        module RequestTooLarge
          extend Support::Extension

          apply_extension do
            handle Pakyow::RequestTooLarge, as: 413 do |_error, connection:|
              connection.headers.clear
              connection.body = StringIO.new("413 Payload Too Large")
              connection.halt
            end
          end
        end
      end
    end
  end
end
