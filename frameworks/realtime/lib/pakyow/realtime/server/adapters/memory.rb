# frozen_string_literal: true

require "concurrent/array"
require "concurrent/hash"
require "concurrent/scheduled_task"

require "pakyow/support/deep_freeze"

module Pakyow
  module Realtime
    class Server
      module Adapters
        # Manages websocket channels in memory.
        #
        # Great for development, not for use in production!
        #
        # @api private
        class Memory
          include Support::DeepFreeze
          insulate :socket_ids_by_channel, :channels_by_socket_id, :expirations_for_socket_id, :socket_instances_by_socket_id

          def initialize(server, _config)
            @server = server

            @socket_ids_by_channel = Concurrent::Hash.new
            @channels_by_socket_id = Concurrent::Hash.new
            @expirations_for_socket_id = Concurrent::Hash.new
            @socket_instances_by_socket_id = Concurrent::Hash.new
          end

          def connect
            # intentionally empty
          end

          def disconnect
            # intentionally empty
          end

          def socket_subscribe(socket_id, *channels)
            channels.each do |channel|
              channel = channel.to_s.to_sym
              (@socket_ids_by_channel[channel] ||= Concurrent::Array.new) << socket_id
              (@channels_by_socket_id[socket_id] ||= Concurrent::Array.new) << channel
            end
          end

          def socket_unsubscribe(*channels)
            channels.each do |channel|
              channel = Regexp.new(channel.to_s)

              @socket_ids_by_channel.select { |key|
                key.to_s.match?(channel)
              }.each do |key, socket_ids|
                @socket_ids_by_channel.delete(key)

                socket_ids.each do |socket_id|
                  @channels_by_socket_id[socket_id]&.delete(key)
                end
              end
            end
          end

          def subscription_broadcast(channel, message)
            @server.transmit_message_to_connection_ids(message, socket_ids_for_channel(channel))
          end

          def expire(socket_id, seconds)
            task = Concurrent::ScheduledTask.execute(seconds) {
              channels_for_socket_id(socket_id).each do |channel|
                @channels_by_socket_id.delete(socket_id)
                @socket_ids_by_channel[channel].delete(socket_id)
                @socket_instances_by_socket_id.delete(socket_id)
              end
            }

            @expirations_for_socket_id[socket_id] ||= []
            @expirations_for_socket_id[socket_id] << task
          end

          def persist(socket_id)
            (@expirations_for_socket_id[socket_id] || []).each(&:cancel)
            @expirations_for_socket_id.delete(socket_id)
          end

          def expiring?(socket_id)
            @expirations_for_socket_id[socket_id]&.any?
          end

          def current!(socket_id, socket_instance_id)
            @socket_instances_by_socket_id[socket_id] = socket_instance_id
          end

          def current?(socket_id, socket_instance_id)
            @socket_instances_by_socket_id[socket_id] == socket_instance_id
          end

          SERIALIZABLE_IVARS = %i[
            @socket_ids_by_channel
            @channels_by_socket_id
            @socket_instances_by_socket_id
          ].freeze

          def serialize
            SERIALIZABLE_IVARS.each_with_object({}) do |ivar, hash|
              hash[ivar] = instance_variable_get(ivar)
            end
          end

          protected

          def socket_ids_for_channel(channel)
            channel = Regexp.new(channel.to_s)

            @socket_ids_by_channel.select { |key|
              key.to_s.match?(channel)
            }.each_with_object([]) do |(_, socket_ids_for_channel), socket_ids|
              socket_ids.concat(
                socket_ids_for_channel.reject { |socket_id|
                  expiring?(socket_id)
                }
              )
            end
          end

          def channels_for_socket_id(socket_id)
            @channels_by_socket_id[socket_id] || []
          end
        end
      end
    end
  end
end
