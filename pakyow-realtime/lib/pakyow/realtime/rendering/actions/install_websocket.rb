# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Realtime
    module Rendering
      module Actions
        class InstallWebsocket
          def call(renderer)
            if renderer.socket_client_id
              renderer.presenter.view.object.each_significant_node(:meta) do |node|
                case node.attributes[:name]
                when "pw-socket"
                  endpoint = renderer.connection.app.config.realtime.endpoint
                  unless endpoint
                    endpoint = if Pakyow.config.server.proxy
                      # Connect directly to the app in development, since the proxy does not support websocket connections.
                      #
                      File.join("ws://#{Pakyow.config.server.host}:#{Pakyow.config.server.port}", renderer.connection.app.config.realtime.path)
                    else
                      File.join("#{renderer.connection.secure? ? "wss" : "ws"}://#{renderer.connection.authority}", renderer.connection.app.config.realtime.path)
                    end
                  end

                  node.attributes["data-config"] = "endpoint: #{endpoint}?id=#{renderer.connection.verifier.sign(renderer.socket_client_id)}"
                end
              end
            end
          end
        end
      end
    end
  end
end
