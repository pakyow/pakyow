# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/view"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        module Realtime
          module InstallWebsocket
            extend Support::Extension

            apply_extension do
              build do |view|
                if (head = view.head)
                  head.append(Support::SafeStringHelpers.html_safe("<meta name=\"pw-socket\" ui=\"socket\">"))
                end
              end

              attach do |presenter, app:|
                presenter.render node: -> {
                  node = object.each_significant_node(:meta).find { |meta_node|
                    meta_node.attributes[:name] == "pw-socket"
                  }

                  unless node.nil?
                    Pakyow::Presenter::View.from_object(node)
                  end
                } do
                  endpoint = app.config.realtime.endpoint || File.join(
                    "#{presentables[:__ws_protocol]}://#{presentables[:__ws_authority]}",
                    app.config.realtime.path
                  )

                  attributes["data-ui"] = "socket(global: true, endpoint: #{endpoint}?id=#{presentables[:__verifier].sign(presentables[:__socket_client_id])})"
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
end
