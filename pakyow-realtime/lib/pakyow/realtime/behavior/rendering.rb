# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          subclass :Renderer do
            before :render do
              next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

              # embed the socket connection id (used by pakyow.js to idenfity itself with the server)
              head.append("<meta name=\"pw-connection-id\" content=\"#{socket_client_id}:#{socket_digest(socket_client_id)}\">\n")

              # embed the endpoint we'll be connecting to
              endpoint = @connection.app.config.realtime.endpoint

              unless endpoint
                endpoint = if (Pakyow.env?(:development) || Pakyow.env?(:prototype)) && Pakyow.host && Pakyow.port
                  # Connect directly to the app in development, since the proxy
                  # does not support websocket connections.
                  #
                  File.join("ws://#{Pakyow.host}:#{Pakyow.port}", @connection.app.config.realtime.path)
                else
                  File.join("#{@connection.ssl? ? "wss" : "ws"}://#{@connection.request.host_with_port}", @connection.app.config.realtime.path)
                end
              end

              head.append("<meta name=\"pw-endpoint\" content=\"#{endpoint}\">\n")
            end
          end
        end
      end
    end
  end
end
