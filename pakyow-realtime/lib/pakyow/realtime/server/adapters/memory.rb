# frozen_string_literal: true

require "concurrent/array"
require "concurrent/hash"
require "concurrent/scheduled_task"

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
          def initialize(server, _config)
            @server = server

            @socket_ids_by_channel = Concurrent::Hash.new
            @channels_by_socket_id = Concurrent::Hash.new
            @expirations_for_socket_id = Concurrent::Hash.new
          end

          def socket_subscribe(socket_id, channel)
            channel = channel.to_sym
            (@socket_ids_by_channel[channel] ||= Concurrent::Array.new) << socket_id
            (@channels_by_socket_id[socket_id] ||= Concurrent::Array.new) << channel
          end

          def socket_unsubscribe(socket_id, channel)
            channel = channel.to_sym
            @socket_ids_by_channel[channel]&.delete(socket_id)
            @channels_by_socket_id[socket_id]&.delete(channel)
          end

          def subscription_broadcast(channel, message)
            @server.transmit_message_to_connection_ids(message, socket_ids_for_channel(channel))
          end

          def expire(socket_id, seconds)
            task = Concurrent::ScheduledTask.execute(seconds) {
              channels_for_socket_id(socket_id).each do |channel|
                socket_unsubscribe(socket_id, channel)
              end
            }

            @expirations_for_socket_id[socket_id] ||= []
            @expirations_for_socket_id[socket_id] << task
          end

          def persist(socket_id)
            (@expirations_for_socket_id[socket_id] || []).each(&:cancel)
            @expirations_for_socket_id.delete(socket_id)
          end

          protected

          def socket_ids_for_channel(channel)
            @socket_ids_by_channel[channel.to_sym] || []
          end

          def channels_for_socket_id(socket_id)
            @channels_by_socket_id[socket_id] || []
          end
        end
      end
    end
  end
end
