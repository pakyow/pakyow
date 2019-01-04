# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      # Silences asset requests from being logged.
      #
      module Silencing
        extend Support::Extension

        apply_extension do
          after :configure do
            unless config.realtime.log_initial_request
              Pakyow.silence do |connection|
                connection.path.start_with?(File.join("/", config.realtime.path))
              end
            end
          end
        end
      end
    end
  end
end
