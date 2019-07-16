# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Config
      module Realtime
        extend Support::Extension

        apply_extension do
          configurable :realtime do
            setting :adapter_settings, {}
            setting :path, "pw-socket"
            setting :endpoint
            setting :log_initial_request, false

            defaults :production do
              setting :adapter_settings do
                { key_prefix: [Pakyow.config.redis.key_prefix, config.name].join("/") }
              end

              setting :log_initial_request, true
            end

            configurable :timeouts do
              # Give sockets 60 seconds to connect before cleaning up their state.
              #
              setting :initial, 60

              # When a socket disconnects, keep state around for 24 hours before
              # cleaning up. This improves the user experience in cases such as
              # when a browser window is left open on a sleeping computer.
              #
              setting :disconnect, 24 * 60 * 60
            end
          end
        end
      end
    end
  end
end
