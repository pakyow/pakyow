# frozen_string_literal: true

require "cgi"

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          isolated :ViewRenderer do
            before :render, priority: :high do
              next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

              endpoint = @connection.app.config.realtime.endpoint

              unless endpoint
                endpoint = if (Pakyow.env?(:development) || Pakyow.env?(:prototype)) && Pakyow.host && Pakyow.port
                  # Connect directly to the app in development, since the proxy does not support websocket connections.
                  #
                  File.join("ws://#{Pakyow.host}:#{Pakyow.port}", @connection.app.config.realtime.path)
                else
                  File.join("#{@connection.ssl? ? "wss" : "ws"}://#{@connection.request.host_with_port}", @connection.app.config.realtime.path)
                end
              end

              head.append(
                <<~HTML
                  <meta name="pw-socket" ui="socket" config="endpoint: #{endpoint}?id=#{CGI::escape("#{socket_client_id}:#{socket_digest(socket_client_id)}")}">
                HTML
              )
            end
          end
        end
      end
    end
  end
end
