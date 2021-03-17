# frozen_string_literal: true

require "json"
require "securerandom"

require "core/async"

require "pakyow/application/helpers/app"
require "pakyow/application/helpers/connection"

require "async/websocket"

require "protocol/websocket/connection"
require "protocol/websocket/headers"

module Pakyow
  module Realtime
    class WebSocket
      Frame = ::Protocol::WebSocket::Frame

      class Connection < ::Protocol::WebSocket::Connection
        include ::Protocol::WebSocket::Headers

        def self.call(framer, protocol = [], **options)
          new(framer, Array(protocol).first, **options)
        end

        def initialize(framer, protocol = nil, **options)
          super(framer, **options)
          @protocol = protocol
        end

        attr :protocol

        def call
          close
        end
      end

      include Is::Async

      include Pakyow::Application::Helpers::Application
      include Pakyow::Application::Helpers::Connection

      attr_reader :id, :connection, :logger

      def initialize(id, connection)
        @id, @connection, @open = id, connection, false
        @logger = Logger.new(:sock, id: @id[0..7], output: Pakyow.output, level: Pakyow.config.logger.level)
        open
      end

      def open?
        @open == true
      end

      def transmit(message, raw: false)
        if open?
          if raw
            @socket.write(message)
          else
            @socket.write(JSON.dump(payload: message))
          end

          @socket.flush
        end
      end

      def beat
        transmit("beat")
      end

      def shutdown
        if open?
          stop_heartbeat
          Server.socket_disconnect(self)
          @open = false
          @logger.info "shutdown"
        end
      end

      # @api private
      def leave
        trigger_presence(:leave)
      end

      private

      def open
        response = Async::WebSocket::Adapters::Native.open(@connection.request, handler: Connection) { |socket|
          begin
            original_logger = @logger
            Pakyow.logger.set(@logger)
            @logger = Pakyow.logger

            @socket = socket

            handle_open
            while (message = socket.read)
              handle_message(message)
            end
          rescue EOFError, Protocol::WebSocket::ClosedError
          ensure
            @socket&.close
            shutdown

            @logger = original_logger
          end
        }

        @connection.__getobj__.instance_variable_set(:@response, response)
      end

      def handle_open
        Server.socket_connect(self)
        @open = true
        trigger_presence(:join)
        @logger.info "opened"
        transmit_system_info
        start_heartbeat
      end

      def handle_message(raw)
        @logger.internal do
          "< " + raw
        end

        message = JSON.parse(raw)
        if (handlers = @connection.app.class.__websocket_handlers[message["type"]])
          handlers.each do |handler|
            instance_exec(message["payload"], &handler)
          end
        end
      end

      def trigger_presence(event)
        @connection.app.each_hook(:before, event) do |hook|
          instance_exec(&hook[:block])
        end
      end

      def transmit_system_info
        transmit({
          channel: "system",
          message: {
            version: @connection.app.config.version
          }
        })
      end

      HEARTBEAT_INTERVAL = 1

      def start_heartbeat
        @heartbeat = async {
          loop do
            sleep(HEARTBEAT_INTERVAL)
            beat
          end
        }
      end

      def stop_heartbeat
        @heartbeat&.cancel
      end
    end
  end
end

module Async
  module WebSocket
    module Adapters
      module Native
        include ::Protocol::WebSocket::Headers

        def self.websocket?(request)
          request.headers.include?("upgrade")
        end

        def self.open(request, headers: [], protocols: [], handler: Connection, **options)
          if websocket?(request) && Array(request.protocol).include?(PROTOCOL)
            # Select websocket sub-protocol:
            if (requested_protocol = request.headers[SEC_WEBSOCKET_PROTOCOL])
              protocol = (requested_protocol & protocols).first
            end

            Response.for(request, headers, protocol: protocol, **options) do |stream|
              framer = Protocol::WebSocket::Framer.new(stream)

              yield handler.call(framer, protocol)
            end
          end
        end
      end
    end
  end
end
