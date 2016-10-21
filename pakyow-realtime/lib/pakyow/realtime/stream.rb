require "pakyow/support/silenceable"

module Pakyow
  module Realtime
    # Handles incoming / outgoing data for a WebSocket connection.
    #
    class Stream
      include Support::Silenceable

      attr_reader :io, :version

      def initialize(io, version: nil)
        @io = io
        @version = version
        @incoming = WebSocket::Frame::Incoming::Server.new(version: version)
        @handlers = {}

        yield self if block_given?
      end

      def write(data)
        @io.write(
          WebSocket::Frame::Outgoing::Server.new(
            version: @version,
            data: data,
            type: :text
          ).to_s
        )
      end

      def receive(data)
        @incoming << data
        process
      end

      def on(event, &block)
        @handlers[event] = block
      end

      private

      def process
        while (frame = @incoming.next)
          case frame.type
          when :text
            handle :message, frame
          when :close
            handle :close, frame
          end
        end
      end

      def handle(event, frame)
        silence_warnings do
          return unless @handlers.keys.include?(event)
          @handlers[event].call(frame.data)
        end
      end
    end
  end
end
