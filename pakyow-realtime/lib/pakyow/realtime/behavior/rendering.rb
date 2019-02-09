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
              endpoint = if (Pakyow.env?(:development) || Pakyow.env?(:prototype)) && Pakyow.host && Pakyow.port
                # Connect directly to the app in development, since the proxy does not support websocket connections.
                #
                File.join("ws://#{Pakyow.host}:#{Pakyow.port}", @connection.app.config.realtime.path)
              else
                File.join("#{@connection.ssl? ? "wss" : "ws"}://#{@connection.host_with_port}", @connection.app.config.realtime.path)
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
