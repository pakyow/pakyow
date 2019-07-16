# frozen_string_literal: true

require "fileutils"

require "pakyow/support/extension"
require "pakyow/support/serializer"

module Pakyow
  class App
    module Behavior
      module Realtime
        # Persists the in-memory realtime server across restarts.
        #
        module Serialization
          extend Support::Extension

          apply_extension do
            on "shutdown", priority: :high do
              if Pakyow.config.realtime.adapter == :memory && instance_variable_defined?(:@websocket_server)
                realtime_server_serializer.serialize
              end
            end

            after "boot" do
              if Pakyow.config.realtime.adapter == :memory
                realtime_server_serializer.deserialize
              end
            end
          end

          private def realtime_server_serializer
            Support::Serializer.new(
              @websocket_server.adapter,
              name: "#{config.name}-realtime",
              path: File.join(
                Pakyow.config.root, "tmp", "state"
              ),
              logger: Pakyow.logger
            )
          end
        end
      end
    end
  end
end
