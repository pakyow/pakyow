# frozen_string_literal: true

require "pakyow/realtime/channel"

module Pakyow
  class Application
    module Helpers
      module Realtime
        module Subscriptions
          def subscribe(channel, *qualifiers)
            channels = if qualifiers.empty?
              Pakyow::Realtime::Channel.new(channel)
            else
              qualifiers.map { |qualifier|
                Pakyow::Realtime::Channel.new(channel, qualifier)
              }
            end

            app.websocket_server.socket_subscribe(socket_client_id, *channels)
          end

          def unsubscribe(channel, *qualifiers)
            channels = if qualifiers.empty?
              Pakyow::Realtime::Channel.new(channel, "*")
            else
              qualifiers.map { |qualifier|
                Pakyow::Realtime::Channel.new(channel, qualifier)
              }
            end

            app.websocket_server.socket_unsubscribe(*channels)
          end
        end
      end
    end
  end
end
