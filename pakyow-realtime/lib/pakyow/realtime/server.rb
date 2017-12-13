# frozen_string_literal: true

require "concurrent/array"
require "concurrent/timer_task"
require "concurrent/executor/thread_pool_executor"

require "websocket/driver"

require "pakyow/realtime/websocket"
require "pakyow/realtime/event_loop"

module Pakyow
  module Realtime
    class Server
      class << self
        def call(state)
          return unless Pakyow.config.realtime.server
          return unless state.request.path == "/pw-socket"
          return unless ::WebSocket::Driver.websocket?(state.request.env)
          return unless id_and_digest = state.request.params[:id]

          id, digest = id_and_digest.split(":", 2)
          key = state.request.session[:socket_server_id]

          # Verify that the websocket is connecting with a valid digest.
          #
          # We expect to receive an id and digest, separated by a colon. The digest is
          # generated from the id along with the key. When the client is a browser, the
          # `id:digest` value is embedded in the response, while the key is stored in
          # the session. We verify by generating the digest and comparing it to the
          # digest sent in the connection attempt.
          return unless key && id && digest == socket_digest(key, id)

          WebSocket.new(id, state)
          state.processed
          throw :halt
        end

        def handle_missing(_state); end

        def handle_failure(_state, _error); end

        # Returns a key.
        #
        def socket_server_id
          SecureRandom.hex(24)
        end

        # Returns a connection id (used throughout the current request lifecycle).
        #
        def socket_client_id
          SecureRandom.hex(24)
        end

        # Returns a digest created from the connection id and socket key.
        #
        def socket_digest(socket_server_id, socket_client_id)
          Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), socket_server_id, socket_client_id)).strip()
        end
      end

      HEARTBEAT_INTERVAL = 3

      # How long we want to wait before cleaning up channel subscriptions. We set all subscriptions
      # to expire when they are initially created. This way if the WebSocket never connects the
      # subscription will be cleaned up for us, preventing orphaned subscriptions. We schedule an
      # expiration on disconnect for the same reason.
      #
      # When the WebSocket connects, we cancel the expiration with persist.
      #
      SUBSCRIPTION_TIMEOUT = 60

      def initialize(adapter = :memory, adapter_config = {})
        require "pakyow/realtime/server/adapters/#{adapter}"
        @adapter = Adapter.const_get(adapter.to_s.capitalize).new(self, adapter_config)

        start_heartbeat
        @event_loop = EventLoop.new
        @sockets = Concurrent::Array.new
        @executor = Concurrent::ThreadPoolExecutor.new

        at_exit {
          @sockets.each(&:shutdown)
        }
      rescue LoadError => e
        Pakyow.logger.error "Failed to load data subscriber store adapter named `#{adapter}'"
        Pakyow.logger.error e.message
      end

      def socket_connect(id_or_socket)
        find_socket(id_or_socket) do |socket|
          @event_loop << socket
          @sockets << socket
          @adapter.persist(socket.id)
        end
      end

      def socket_disconnect(id_or_socket)
        find_socket(id_or_socket) do |socket|
          @event_loop.rm(socket)
          @sockets.delete(socket)
          @adapter.expire(socket.id, SUBSCRIPTION_TIMEOUT)
        end
      end

      def socket_subscribe(id_or_socket, channel)
        find_socket_id(id_or_socket) do |socket_id|
          @adapter.socket_subscribe(socket_id, channel.to_s)
          @adapter.expire(socket_id, SUBSCRIPTION_TIMEOUT)
        end
      end

      def socket_unsubscribe(channel)
        @adapter.socket_unsubscribe(channel.to_s)
      end

      def subscription_broadcast(channel, message)
        @adapter.subscription_broadcast(channel.to_s, channel: channel.name, message: message)
      end

      # Called by the adapter, which guarantees that this server has connections for these ids.
      #
      def transmit_message_to_connection_ids(message, socket_ids)
        socket_ids.each do |socket_id|
          find_socket_by_id(socket_id)&.transmit(message)
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

      protected

      def start_heartbeat
        @heartbeat = Concurrent::TimerTask.new(execution_interval: HEARTBEAT_INTERVAL) do
          @executor << -> {
            @sockets.each(&:beat)
          }
        end

        @heartbeat.execute
      end
    end
  end
end
