# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module UI
    module Behavior
      module Timeouts
        extend Support::Extension

        apply_extension do
          on :join do
            @connection.app.data.persist(@id)
          end

          on :leave do
            @connection.app.data.expire(@id, config.realtime.timeouts.disconnect)
          end
        end
      end
    end
  end
end
