# frozen_string_literal: true

require "pakyow/support/class_state"
require "pakyow/support/deep_freeze"
require "pakyow/support/message_verifier"

require_relative "websocket"

module Pakyow
  module Realtime
    class Server
      class << self
        include Support::DeepFreeze
        insulate :queue

        def run(adapter, adapter_config, timeout_config)
          new(adapter, adapter_config, timeout_config).run
        end

        def socket_connect(id_or_socket)
          queue << proc {
            find_socket(id_or_socket) do |socket|
              @sockets << socket
              @adapter.persist(socket.id)
              @adapter.current!(socket.id, socket.object_id)
            end
          }
        end

        def socket_disconnect(id_or_socket)
          queue << proc {
            find_socket(id_or_socket) do |socket|
              @sockets.delete(socket)

              # If this isn't the current instance for the socket id, it means that a
              # reconnect probably happened and the new socket connected before we
              # knew that the old one disconnected. Since there's a newer socket,
              # don't trigger leave events or expirations for the old one.
              #
              if @adapter.current?(socket.id, socket.object_id)
                socket.leave
                @adapter.expire(socket.id, @timeout_config.disconnect)
              end
            end
          }
        end

        def socket_subscribe(id_or_socket, *channels)
          queue << proc {
            find_socket_id(id_or_socket) do |socket_id|
              @adapter.socket_subscribe(socket_id, *channels)
              @adapter.expire(socket_id, @timeout_config.initial)
            end
          }
        end

        def socket_unsubscribe(*channels)
          queue << proc {
            @adapter.socket_unsubscribe(*channels)
          }
        end

        def subscription_broadcast(channel, message)
          queue << proc {
            @adapter.subscription_broadcast(channel.to_s, channel: channel.name, message: message)
          }
        end
      end

      extend Support::ClassState
      class_state :queue, default: Queue.new

      include Support::DeepFreeze
      insulate :sockets

      attr_reader :adapter

      def initialize(adapter, adapter_config, timeout_config)
        @sockets = []

        require "pakyow/realtime/server/adapters/#{adapter}"
        @adapter = Adapters.const_get(adapter.to_s.capitalize).new(self, adapter_config)
        @timeout_config = timeout_config
      rescue LoadError => e
        Pakyow.logger.error "Failed to load data subscriber store adapter named `#{adapter}'"
        Pakyow.logger.error e.message
      end

      def run
        @adapter.connect

        while (block = self.class.queue.pop)
          begin
            instance_eval(&block)
          rescue => error
            Pakyow.houston(error)
          end
        end
      ensure
        @adapter.disconnect
      end

      def shutdown
        @sockets.each(&:shutdown)

        until self.class.queue.empty?
          sleep 1
        end
      ensure
        self.class.queue.close
      end

      # Called by the adapter, which guarantees that this server has connections for these ids.
      #
      def transmit_message_to_connection_ids(message, socket_ids, raw: false)
        socket_ids.each do |socket_id|
          find_socket_by_id(socket_id)&.transmit(message, raw: raw)
        end
      end

      def find_socket_by_id(socket_id)
        @sockets.find { |socket| socket.id == socket_id }
      end

      def find_socket(id_or_socket)
        socket = if id_or_socket.is_a?(WebSocket)
          id_or_socket
        else
          find_socket_by_id(id_or_socket)
        end

        yield socket if socket
      end

      def find_socket_id(id_or_socket)
        socket_id = if id_or_socket.is_a?(WebSocket)
          id_or_socket.id
        else
          id_or_socket
        end

        yield socket_id if socket_id
      end
    end
  end
end
