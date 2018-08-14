# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Realtime
      module Config
        extend Support::Extension

        apply_extension do
          configurable :realtime do
            setting :server, true

            setting :adapter, :memory
            setting :adapter_settings, {}

            defaults :production do
              setting :adapter, :redis
              setting :adapter_settings do
                @adapter_settings ||= Pakyow.config.redis.dup
              end
            end
          end
        end
      end
    end
  end
end
