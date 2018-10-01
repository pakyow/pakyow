# frozen_string_literal: true

require "securerandom"

require "pakyow/helpers/connection"

module Pakyow
  module Realtime
    class WebSocket
      include Pakyow::Helpers::Connection

      attr_reader :id, :io, :env, :url

      def initialize(id, connection)
        @id, @connection = id, connection
        @open = false

        @logger = Logger::RequestLogger.new(:sock, id: @id[0..7])
        @env = @connection.env

        secure = @connection.ssl?
        scheme = secure ? "wss:" : "ws:"
        @url = scheme + "//" + @connection.env["HTTP_HOST"] + @connection.env["REQUEST_URI"]

        @io = @connection.env["rack.hijack"].call

        @driver = ::WebSocket::Driver.rack(self)
        @driver.on(:open)    do |_e| handle_open end
        @driver.on(:message) do |e| handle_message(e.data) end
        @driver.on(:close)   do |e| handle_close(e.reason, e.code) end
        @driver.on(:error)   do |e| handle_error(e.message) end
        @driver.start

        @connection.app.websocket_server.socket_connect(self)
      end

      def open?
        @open == true
      end

      def transmit(message, raw: false)
        if open?
          @driver.text(raw ? message : { payload: message }.to_json)
        end
      end

      def beat
        transmit("beat")
      end

      def shutdown
        return unless open?

        @connection.app.websocket_server.socket_disconnect(self)
        @io.close if @io
        @io = nil

        @open = false
        trigger_presence(:leave)
        @logger.info "shutdown"
      end

      def write(string)
        @logger.verbose("> " + string)
        @io.write(string)
      rescue
        shutdown
      end

      def receive(data)
        @driver.parse(data)
      rescue
        shutdown
      end

      protected

      def handle_open
        @open = true
        trigger_presence(:join)
        @logger.info "opened"
      end

      def handle_message(message)
        @logger.verbose("< " + message)
      end

      def handle_close(_code, _reason)
        shutdown
      end

      def handle_error(_message)
        shutdown
      end

      def trigger_presence(event)
        @connection.app.hooks(:before, event).each do |hook, _|
          instance_exec(&hook)
        end
      end
    end
  end
end
