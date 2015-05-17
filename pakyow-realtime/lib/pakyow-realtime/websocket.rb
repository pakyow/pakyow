require 'websocket_parser'
require_relative 'connection'

module Pakyow
  module Realtime
    # A class for all the websockety stuff.
    #
    # @api private
    class Websocket < Connection
      include Celluloid
      finalizer :shutdown

      def initialize(req, key)
        @req = req
        @key = key

        @handshake = handshake!(req)
        @socket = hijack!(req)

        if @handshake.valid?
          response = @handshake.accept_response
          response.render(@socket)
          setup
        else
          error = @handshake.errors.first

          response = Rack::Response.new(400)
          response.render(@socket)

          raise HandshakeError, "error during handshake: #{error}"
        end
      end

      def shutdown
        @timer.cancel if @timer
        @socket.close if @socket && !@socket.closed?
      end

      def push(msg)
        logger.debug "(#{@key}): sending message #{msg}"
        WebSocket::Message.new(msg.to_json).write(@socket)
      end

      private

      def handshake!(req)
        headers = {
          'Upgrade' => req.env['HTTP_UPGRADE'],
          'Sec-WebSocket-Version' => req.env['HTTP_SEC_WEBSOCKET_VERSION'],
          'Sec-Websocket-Key' => req.env['HTTP_SEC_WEBSOCKET_KEY'],
        }

        WebSocket::ClientHandshake.new(:get, req.url, headers)
      end

      def hijack!(req)
        req.env['rack.hijack'].call
        req.env['rack.hijack_io']
      end

      def setup
        @parser = WebSocket::Parser.new

        @parser.on_message do |ws_message|
          begin
            logger.debug "(#{@key}): received message #{ws_message}"
            push(MessageHandler.handle(JSON.parse(ws_message), @req.env['rack.session']))
          rescue Exception => e
            logger.error 'Websocket encountered an error:'
            logger.error e.message
            e.backtrace.each do |line|
              logger.error line
            end
          end
        end

        @parser.on_error do |m|
          logger.error "Received error #{m}"
          shutdown
        end

        @parser.on_close do |status, message|
          @socket << WebSocket::Message.close.to_data
          delegate.unregister(@key)
          shutdown

          logger.info "Client closed connection. Status: #{status}. Reason: #{message}"
          terminate
        end

        @parser.on_ping do |payload|
          @socket << WebSocket::Message.pong(payload).to_data
        end

        @timer = Celluloid.every(0.1) { read }
      end

      def read
        begin
          @parser << @socket.read_nonblock(16384)
        rescue ::IO::WaitReadable
        end
      end
    end

    class HandshakeError < Exception
    end
  end
end
