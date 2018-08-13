# frozen_string_literal: true

module Pakyow
  module Realtime
    module Helpers
      module Subscriptions
        def subscribe(channel, *qualifiers)
          channels = if qualifiers.empty?
            Channel.new(channel)
          else
            qualifiers.map { |qualifier|
              Channel.new(channel, qualifier)
            }
          end

          @connection.app.websocket_server.socket_subscribe(socket_client_id, *channels)
        end

        def unsubscribe(channel, *qualifiers)
          channels = if qualifiers.empty?
            Channel.new(channel, "*")
          else
            qualifiers.map { |qualifier|
              Channel.new(channel, qualifier)
            }
          end

          @connection.app.websocket_server.socket_unsubscribe(*channels)
        end
      end
    end
  end
end
