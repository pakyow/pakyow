# frozen_string_literal: true

require "securerandom"

module Pakyow
  module Realtime
    class WebSocket
      include Helpers

      attr_reader :env, :url

      # TODO: register and trigger message handlers
      # TODO: channels, including subscribe/unsubscribe/transmission
      # TODO: force disconnects on the current connection, or by id
      # TODO: make it production ready using redis pubsub
      # TODO: register and trigger join/leave handlers

      def initialize(state)
        @__state = state

        @env = request.env

        secure = request.ssl?
        scheme = secure ? "wss:" : "ws:"
        @url = scheme + "//" + env["HTTP_HOST"] + env["REQUEST_URI"]

        @io = @env["rack.hijack"].call

        @driver = ::WebSocket::Driver.rack(self)
        @driver.on(:open)    do |_e| handle_open end
        @driver.on(:message) do |e| handle_message(e.data) end
        @driver.on(:close)   do |e| handle_close(e.reason, e.code) end
        @driver.on(:error)   do |e| handle_error(e.message) end
        @driver.start

        app.websocket_server.socket_connect(self)
      end

      def transmit(message)
        return unless @open
        @driver.text(message)
      end

      def beat
        transmit("beat")
      end

      def shutdown
        app.websocket_server.socket_disconnect(self)
        @io.close if @io
        @io = nil
      end

      def handle_open
        @open = true
      end

      def handle_message(message)
        puts message
      end

      def handle_close(_code, _reason)
        shutdown
      end

      def handle_error(_message)
        shutdown
      end

      def write(string)
        @io.write(string)
      rescue
        shutdown
      end

      def receive(data)
        @driver.parse(data)
      rescue
        shutdown
      end

      def to_io
        @io
      end
    end
  end
end
