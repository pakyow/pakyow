# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../../realtime/server"

module Pakyow
  class Application
    module Behavior
      module Realtime
        module Server
          extend Support::Extension

          apply_extension do
            attr_reader :websocket_server

            after "initialize", priority: :high do
              @websocket_server = if is_a?(Plugin)
                parent.websocket_server
              else
                Pakyow::Realtime::Server.new(
                  Pakyow.config.realtime.adapter,
                  Pakyow.config.realtime.adapter_settings.to_h.merge(
                    config.realtime.adapter_settings.to_h
                  ),
                  config.realtime.timeouts
                )
              end
            end

            on "shutdown" do
              if instance_variable_defined?(:@websocket_server)
                @websocket_server.shutdown
              end
            end
          end
        end
      end
    end
  end
end
