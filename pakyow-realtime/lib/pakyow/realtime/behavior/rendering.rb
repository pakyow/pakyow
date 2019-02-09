# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          post_process do |html|
            unless endpoint = config.realtime.endpoint
              endpoint = if Pakyow.config.server.proxy
                # Connect directly to the app in development, since the proxy does not support websocket connections.
                #
                File.join("ws://#{Pakyow.config.server.host}:#{Pakyow.config.server.port}", @connection.app.config.realtime.path)
              else
                File.join("#{@connection.secure? ? "wss" : "ws"}://#{@connection.authority}", @connection.app.config.realtime.path)
              end
            end

            html.sub!("{{pw-socket-config}}", "endpoint: #{endpoint}?id=#{@connection.verifier.sign(socket_client_id)}")

            html
          end
        end
      end
    end
  end
end
