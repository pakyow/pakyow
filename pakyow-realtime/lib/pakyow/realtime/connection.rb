require "websocket"

require "pakyow/core/logger/request_logger"

require "pakyow/realtime/stream"
require "pakyow/realtime/delegate"
require "pakyow/realtime/connection_pool"

module Pakyow
  module Realtime
    # Realtime WebSocket.
    #
    class Connection
      # Returns a key.
      #
      def self.socket_key
        SecureRandom.hex(32)
      end

      # Returns a connection id (used throughout the current request lifecycle).
      #
      def self.socket_connection_id
        SecureRandom.hex(32)
      end

      # Returns a digest created from the connection id and socket key.
      #
      def self.socket_digest(socket_key, socket_connection_id)
        Digest::SHA1.hexdigest("--#{socket_key}--#{socket_connection_id}--")
      end
      
      @event_handlers = {}

      # Register a callback for an event.
      #
      def self.on(event, &block)
        (@event_handlers[event.to_sym] ||= []) << block
      end
      
      attr_reader :key, :logger, :stream

      def initialize(io, version: nil, env: {}, key: "")
        @io = io
        @env = env
        @key = key
        
        @delegate = Delegate.instance
        @logger = Logger::RequestLogger.new(:sock, id: @key[0..7])

        @stream = Stream.new(io, version: version) do |stream|
          stream.on :message do |m|
            handle_message(m)
          end

          stream.on :error do |e|
            handle_error(e)
          end

          stream.on :close do |s, m|
            handle_close(s, m)
          end
        end

        @logger.info "client established connection"
        @delegate.register(@key, self)
        handle_ws_join
      end
  
      # Write to the io object.
      #
      def write(msg)
        @logger.verbose ">> #{msg}"
        @stream.write(msg)
      rescue StandardError => e
        @logger.error "fatal error:"
        @logger.error e.message

        # something went wrong (like a broken pipe); shutdown
        # and let the socket reconnect if it's still around
        shutdown
      end
      
      # Send incoming data to the stream for processing.
      #
      def receive(data)
        @stream.receive(data)
      end

      # Shutdown this connection.
      #
      def shutdown
        ConnectionPool.instance.rm(self)
        @delegate.unregister(@key)
        self.class.handle_event(:leave, @env)
        @io.close if @io
        @io = nil
      end

      def to_io
        @io
      end

      private

      def handle_message(message)
        parsed = JSON.parse(message)
        @logger.verbose "<< #{message}"
        write(MessageHandler.handle(parsed, @env['rack.session']).to_json)
      end

      def handle_error(_error)
        shutdown
      end

      def handle_close(_status, _message)
        shutdown
      end
      
      def handle_ws_join
        self.class.handle_event(:join, @env)
      end

      def self.handle_event(event, env)
        context = CallContext.new(env)

        event_handlers(event).each do |block|
          context.instance_exec(&block)
        end
      end

      def self.event_handlers(event = nil)
        @event_handlers.fetch(event, [])
      end
    end
  end
end
