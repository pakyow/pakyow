# frozen_string_literal: true

require "core/async"

require "async/notification"
require "async/io/unix_endpoint"

require "pakyow/support/deep_freeze"

module Pakyow
  module Runnable
    # Send notifications to a container or service from any process.
    #
    # @api private
    class Notifier
      include Is::Async

      include Support::DeepFreeze
      insulate :child, :parent

      attr_reader :child, :parent

      def initialize
        @messages = []
        @path = File.join(Dir.tmpdir, "pakyow-#{::Process.pid}-#{SecureRandom.hex(4)}.sock")
        @notification = ::Async::Notification.new
        @socket = await { ::Async::IO::Endpoint.unix(@path, :DGRAM).bind }
      end

      def notify(event, **payload)
        message = {event: event, payload: payload}
        socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
        socket.connect(Socket.pack_sockaddr_un(@path))
        socket.sendmsg(Marshal.dump(message))
      rescue SystemCallError
      ensure
        socket&.close
      end

      def listen
        await do
          receive

          while running?
            until @messages.empty?
              message = @messages.shift
              yield message[:event], **message[:payload]
            end

            break unless running?

            @notification.wait
          end
        end
      end

      def stop
        return unless running?

        @notification.signal

        await do
          @socket.close
        end

        @socket = nil
      end

      def running?
        @socket&.connected?
      end

      private def receive
        async do
          while running?
            message = Marshal.load(@socket.recvmsg(4096)[0])
            @messages << message
            @notification.signal
          end
        rescue Async::Wrapper::Cancelled, SystemCallError
        end
      end
    end
  end
end
