# frozen_string_literal: true

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
          return unless state.request.path == "/pw-socket"
          return unless ::WebSocket::Driver.websocket?(state.request.env)
          return unless id_and_digest = state.request.params[:id]

          id, digest = id_and_digest.split(":", 2)

          # Verify that the websocket is connecting with a valid digest.
          #
          # We expect to receive an id and digest, separated by a colon. The digest is
          # generated from the id along with the key. When the client is a browser, the
          # `id:digest` value is embedded in the response, while the key is stored in
          # the session. We verify by generating the digest and comparing it to the
          # digest sent in the connection attempt.
          return unless digest == socket_digest(state.request.session[:socket_key], id)

          WebSocket.new(state)
          state.processed
          throw :halt
        end

        def handle_missing(_state); end

        def handle_failure(_state, _error); end

        # Returns a key.
        #
        def socket_key
          SecureRandom.hex(24)
        end

        # Returns a connection id (used throughout the current request lifecycle).
        #
        def socket_connection_id
          SecureRandom.hex(24)
        end

        # Returns a digest created from the connection id and socket key.
        #
        def socket_digest(socket_key, socket_connection_id)
          Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), socket_key, socket_connection_id)).strip()
        end
      end

      HEARTBEAT_INTERVAL = 3

      def initialize
        start_heartbeat
        @event_loop = EventLoop.new
        @connections = Concurrent::Array.new
        @executor = Concurrent::ThreadPoolExecutor.new
      end

      def socket_connect(socket)
        @event_loop << socket
        @connections << socket
      end

      def socket_disconnect(socket)
        @event_loop.rm(socket)
        @connections.delete(socket)
      end

      protected

      def start_heartbeat
        @heartbeat = Concurrent::TimerTask.new(execution_interval: HEARTBEAT_INTERVAL) do
          @executor << -> {
            @connections.each(&:beat)
          }
        end

        @heartbeat.execute
      end
    end
  end
end
