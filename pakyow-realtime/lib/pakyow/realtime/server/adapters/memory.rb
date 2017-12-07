# frozen_string_literal: true

require "concurrent/hash"

module Pakyow
  module Realtime
    class Server
      module Adapter
        # Manages websocket channels in memory.
        #
        # Great for development, not for use in production!
        #
        # @api private
        class Memory
          def initialize(server)
            @server = server

            @websocket_ids_by_channel = Concurrent::Hash.new
          end

          def socket_subscribe(socket, channel)
            channel = channel.to_sym
            (@websocket_ids_by_channel[channel] ||= Concurrent::Array.new) << socket.id
          end

          def socket_unsubscribe(socket, channel)
            @websocket_ids_by_channel[channel.to_sym]&.delete(socket.id)
          end

          def subscription_broadcast(channel, message)
            @server.transmit_message_to_connection_ids(message, websocket_ids_for_channel(channel))
          end

          protected

          def websocket_ids_for_channel(channel)
            @websocket_ids_by_channel[channel.to_sym] || []
          end
        end
      end
    end
  end
end
