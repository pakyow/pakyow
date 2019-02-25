# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/realtime/server"

module Pakyow
  module Realtime
    module Behavior
      module Server
        extend Support::Extension

        apply_extension do
          unfreezable :websocket_server
          attr_reader :websocket_server

          after :initialize, priority: :high do
            @websocket_server = Realtime::Server.new(
              Pakyow.config.realtime.adapter,
              Pakyow.config.realtime.adapter_settings.to_h.merge(
                config.realtime.adapter_settings.to_h
              ),
              config.realtime.timeouts
            )
          end

          before :shutdown do
            if instance_variable_defined?(:@websocket_server)
              @websocket_server.shutdown
            end
          end

          before :fork do
            @websocket_server.disconnect
          end

          after :fork do
            @websocket_server.connect
          end
        end
      end
    end
  end
end
