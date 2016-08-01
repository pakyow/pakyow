require 'concurrent'
require 'websocket'

require_relative 'connection'

module Pakyow
  module Realtime
    # Hijacks a request, performs the handshake, and creates an async object
    # for handling incoming and outgoing messages in an asynchronous manner.
    #
    # @api private
    class Websocket < Connection
      attr_reader :parser, :socket, :key, :logger

      @event_handlers = {}

      def initialize(req, key)
        @req = req
        @key = key

        @socket = hijack(req)
        @server = handshake(req)
        @logger = Logger::RequestLogger.new(:sock, id: @key[0..7])

        setup
      end

      def registered
        handle_ws_join
      end

      def shutdown
        delegate.unregister(@key)
        self.class.handle_event(:leave, @req)

        @socket.close if @socket && !@socket.closed?
        @shutdown = true

        @reader = nil
      end

      def shutdown?
        @shutdown == true
      end

      def push(msg)
        json = JSON.pretty_generate(msg)
        logger.debug "sending message: #{json}\n"

        frame = WebSocket::Frame::Outgoing::Server.new(
          version: @server.version,
          data: json,
          type: :text)
        @socket.write(frame.to_s)
      rescue StandardError => e
        logger.error "encountered a fatal error:"
        logger.error e.message

        # something went wrong (like a broken pipe); shutdown
        # and let the socket reconnect if it's still around
        shutdown
      end

      def self.on(event, &block)
        (@event_handlers[event.to_sym] ||= []) << block
      end

      private

      def hijack(req)
        if req.env['rack.hijack']
          req.env['rack.hijack'].call
          return req.env['rack.hijack_io']
        else
          logger.info "there's no socket to hijack :("
        end
      end

      def handshake(req)
        data = "#{req.env['REQUEST_METHOD']} #{req.env['REQUEST_URI']} #{req.env['SERVER_PROTOCOL']}\r\n"
        req.env.each_pair do |key, val|
          if key =~ /^HTTP_(.*)/
            name = rack_env_key_to_http_header_name($1)
            data << "#{name}: #{val}\r\n"
          end
        end
        data << "\r\n"

        server = WebSocket::Handshake::Server.new
        server << data

        fail HandshakeError, "error during handshake" unless server.valid?
        @socket.write(server.to_s)

        server
      end

      def rack_env_key_to_http_header_name(key)
        name = key.downcase.gsub('_', '-')
        name[0] = name[0].upcase
        name.gsub!(/-(.)/) do |chr|
          chr.upcase
        end
        name
      end

      def setup
        logger.info "client established connection"

        @parser = Parser.new(version: @server.version)

        @parser.on :message do |message|
          handle_ws_message(message)
        end

        @parser.on :error do |error|
          logger.error "encountered error #{error}"
          handle_ws_error(error)
        end

        @parser.on :close do |status, message|
          logger.info "client closed connection"
          handle_ws_close(status, message)
        end

        Concurrent::Future.execute {
          begin
            loop do
              break if shutdown?
              @parser << @socket.read_nonblock(1024)
            end
          rescue ::IO::WaitReadable
            IO.select([@socket])
            retry
          end
        }
      end

      def handle_ws_message(message)
        parsed = JSON.parse(message)
        logger.debug "(ws.#{@key}) received message: #{JSON.pretty_generate(parsed)}\n"
        push(MessageHandler.handle(parsed, @req.env['rack.session']))
      rescue StandardError => e
        logger.error "encountered an error:"
        logger.error e.message

        e.backtrace.each do |line|
          logger.error line
        end
      end

      def handle_ws_error(_error)
        shutdown
      end

      def handle_ws_join
        self.class.handle_event(:join, @req)
      end

      def handle_ws_close(_status, _message)
        shutdown
      end

      def self.handle_event(event, req)
        context = CallContext.new(req.env)

        event_handlers(event).each do |block|
          context.instance_exec(&block)
        end
      end

      def self.event_handlers(event = nil)
        @event_handlers.fetch(event, [])
      end
    end

    class Parser
      def initialize(version: nil)
        @parser = WebSocket::Frame::Incoming::Server.new(version: version)
        @handlers = {}
      end

      def on(event, &block)
        @handlers[event] = block
      end

      def <<(data)
        @parser << data
        process
      end

      private

      def process
        while (frame = @parser.next)
          case frame.type
          when :text
            handle :message, frame
          when :close
            handle :close, frame
          end
        end
      end

      def handle(event, frame)
        return unless @handlers.keys.include?(event)
        @handlers[event].call(frame.data)
      end
    end
  end
end
