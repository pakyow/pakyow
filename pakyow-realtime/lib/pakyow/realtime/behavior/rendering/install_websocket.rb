# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/view"

module Pakyow
  module Realtime
    module Behavior
      module Rendering
        module InstallWebsocket
          extend Support::Extension

          apply_extension do
            build do |view|
              if head = view.head
                head.append(Support::SafeStringHelpers.html_safe("<meta name=\"pw-socket\" ui=\"socket\">"))
              end
            end

            attach do |presenter, app:|
              presenter.render node: -> {
                node = object.each_significant_node(:meta).find { |meta_node|
                  meta_node.attributes[:name] == "pw-socket"
                }

                unless node.nil?
                  Presenter::View.from_object(node)
                end
              } do
                endpoint = app.config.realtime.endpoint

                unless endpoint
                  endpoint = if Pakyow.config.server.proxy
                    # Connect directly to the app in development, since the proxy does not support websocket connections.
                    #
                    File.join("ws://#{Pakyow.config.server.host}:#{Pakyow.config.server.port}", app.config.realtime.path)
                  else
                    File.join("#{presentables[:__ws_protocol]}://#{presentables[:__ws_authority]}", app.config.realtime.path)
                  end
                end

                attributes["data-config"] = "endpoint: #{endpoint}?id=#{presentables[:__verifier].sign(presentables[:__socket_client_id])}"
              end
            end

            expose do |connection|
              connection.set(:__verifier, connection.verifier)
              connection.set(:__ws_protocol, connection.secure? ? "wss" : "ws")
              connection.set(:__ws_authority, connection.authority)
            end
          end
        end
      end
    end
  end
end
