# frozen_string_literal: true

require "securerandom"

require "pakyow/helpers/app"
require "pakyow/helpers/connection"

require "async/websocket"

module Pakyow
  module Realtime
    class WebSocket
      include Pakyow::Helpers::App
      include Pakyow::Helpers::Connection

      attr_reader :id

      def initialize(id, connection)
        @id, @connection, @open = id, connection, false
        @logger = Logger.new(:sock, id: @id[0..7])
        @server = @connection.app.websocket_server

        if @socket = Async::WebSocket::Incoming.new(@connection.request)
          while event = @socket.next_event
            case event
            when ::WebSocket::Driver::OpenEvent
              handle_open
            when ::WebSocket::Driver::MessageEvent
              handle_message(event.data)
            end
          end
        end
      rescue Async::WebSocket::Incoming::Invalid
        connection.halt
      ensure
        @socket&.close; shutdown
      end

      def open?
        @open == true
      end

      def transmit(message, raw: false)
        if open?
          if raw
            @socket.send_text(message)
          else
            @socket.send_message(payload: message)
          end
        end
      end

      def beat
        transmit("beat")
      end

      # @api private
      def leave
        trigger_presence(:leave)
      end

      private

      def shutdown
        if open?
          @server.socket_disconnect(self)
          @open = false
          @logger.info "shutdown"
        end
      end

      def handle_open
        @server.socket_connect(self)
        @open = true
        trigger_presence(:join)
        @logger.info "opened"
      end

      def handle_message(message)
        @logger.verbose("< " + message)
      end

      def trigger_presence(event)
        @connection.app.hooks(:before, event).each do |hook, _|
          instance_exec(&hook)
        end
      end
    end
  end
end

require "async/io"
require "async/websocket/connection"

module Async
  module WebSocket
    class Incoming < Connection
      class Invalid < StandardError; end

      def initialize(request)
        @env = build_env(request)
        @url = build_url(request)

        if request.hijack? && websocket?(@env)
          @io = hijacked_io(request)
          super(@io, ::WebSocket::Driver.rack(self))
        else
          raise Invalid
        end
      end

      attr :env
      attr :url

      def close
        super; @io.close
      end

      protected

      def websocket?(env)
        ::WebSocket::Driver.websocket?(env)
      end

      def build_env(request)
        {
          "HTTP_CONNECTION" => request.headers["connection"].to_s,
          "HTTP_HOST" => request.headers["host"].to_s,
          "HTTP_ORIGIN" => request.headers["origin"].to_s,
          "HTTP_SEC_WEBSOCKET_EXTENSIONS" => request.headers["sec-websocket-extensions"].to_s,
          "HTTP_SEC_WEBSOCKET_KEY" => request.headers["sec-websocket-key"].to_s,
          "HTTP_SEC_WEBSOCKET_KEY1" => request.headers["sec-websocket-key1"].to_s,
          "HTTP_SEC_WEBSOCKET_KEY2" => request.headers["sec-websocket-key2"].to_s,
          "HTTP_SEC_WEBSOCKET_PROTOCOL" => request.headers["sec-websocket-protocol"].to_s,
          "HTTP_SEC_WEBSOCKET_VERSION" => request.headers["sec-websocket-version"].to_s,
          "HTTP_UPGRADE" => request.headers["upgrade"].to_s,
          "REQUEST_METHOD" => request.method,
          "rack.input" => request.body
        }
      end

      def build_url(request)
        "#{request.scheme}://#{request.authority}#{request.path}"
      end

      def hijacked_io(request)
        wrapper = request.hijack
        io = Async::IO.try_convert(wrapper.io.dup)
        wrapper.close
        io
      end
    end
  end
end
