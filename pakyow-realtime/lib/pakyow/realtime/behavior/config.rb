# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Config
        extend Support::Extension

        apply_extension do
          settings_for :realtime do
            setting :adapter_settings, {}
            setting :path, "pw-socket"
            setting :endpoint
            setting :log_initial_request, false

            defaults :production do
              setting :adapter_settings do
                { key_prefix: ["pw", config.name].join("/") }
              end

              setting :log_initial_request, true
            end
          end
        end
      end
    end
  end
end
