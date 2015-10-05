require 'websocket_parser'
require_relative 'connection'

module Pakyow
  module Realtime
    # Hijacks a request, performs the handshake, and creates a Celluloid actor
    # for handling incoming and outgoing messages in an asynchronous manner.
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

        handle_handshake
      end

      def shutdown
        @timer.cancel if @timer
        @socket.close if @socket && !@socket.closed?
      end

      def push(msg)
        logger.debug "(#{@key}): sending message"
        WebSocket::Message.new(msg.to_json).write(@socket)
      end

      private

      def handshake!(req)
        WebSocket::ClientHandshake.new(:get, req.url, handshake_headers(req))
      end

      def hijack!(req)
        if req.env['rack.hijack']
          req.env['rack.hijack'].call
          return req.env['rack.hijack_io']
        else
          logger.info "there's no socket to hijack :("
          terminate
          return nil
        end
      end
      
      def handshake_headers(req)
        {
          'Upgrade' => req.env['HTTP_UPGRADE'],
          'Sec-WebSocket-Version' => req.env['HTTP_SEC_WEBSOCKET_VERSION'],
          'Sec-Websocket-Key' => req.env['HTTP_SEC_WEBSOCKET_KEY']
        }
      end

      def handle_handshake
        return if @socket.nil?

        if @handshake.valid?
          accept_handshake
          setup
        else
          fail_handshake
        end
      end

      def accept_handshake
        response = @handshake.accept_response
        response.render(@socket)
      end

      def fail_handshake
        error = @handshake.errors.first

        response = Rack::Response.new(400)
        response.render(@socket)

        fail HandshakeError, "error during handshake: #{error}"
      end

      def setup
        @parser = WebSocket::Parser.new

        @parser.on_message do |message|
          logger.debug "(#{@key}): received message"
          handle_ws_message(JSON.parse(message))
        end

        @parser.on_error do |error|
          logger.error "Received error #{error}"
          handle_ws_error(error)
        end

        @parser.on_close do |status, message|
          logger.info "Client closed connection (#{status} | #{message})"
          handle_ws_close(status, message)
        end

        @parser.on_ping do |payload|
          handle_ws_ping(payload)
        end

        @timer = Celluloid.every(0.1) { read }
      end

      def read
        @parser << @socket.read_nonblock(16_384)
      rescue ::IO::WaitReadable
        logger.debug '.'
      rescue EOFError
        delegate.unregister(@key)
        shutdown
      end

      def handle_ws_message(message)
        push(MessageHandler.handle(message, @req.env['rack.session']))
      rescue StandardError => e
        logger.error 'WebSocket encountered an error:'
        logger.error e.message

        e.backtrace.each do |line|
          logger.error line
        end
      end

      def handle_ws_error(_error)
        shutdown
      end

      def handle_ws_close(_status, _message)
        @socket << WebSocket::Message.close.to_data
        delegate.unregister(@key)

        shutdown
        terminate
      end

      def handle_ws_ping(payload)
        @socket << WebSocket::Message.pong(payload).to_data
      end
    end
  end
end
