# frozen_string_literal: true

require "async/notification"
require "async/io/unix_endpoint"

require "pakyow/support/deep_freeze"

module Pakyow
  module Runnable
    # Send notifications to a container or service from any process.
    #
    # @api private
    class Notifier
      include Support::DeepFreeze
      insulate :child, :parent

      attr_reader :child, :parent

      def initialize
        @messages = []
        @path = File.join(Dir.tmpdir, "pakyow-#{::Process.pid}-#{SecureRandom.hex(4)}.sock")
        @notification = ::Async::Notification.new
        @socket = Pakyow.async { ::Async::IO::Endpoint.unix(@path, :DGRAM).bind }.wait
        @endpoint = ::Async::IO::Endpoint.unix(@path, ::Socket::SOCK_DGRAM)
      end

      def notify(event, **payload)
        if running?
          message = {event: event, payload: payload}

          if ::Async::Task.current?
            Pakyow.async {
              @endpoint.connect do |connection|
                connection.sendmsg(Marshal.dump(message))
              end
            }.wait
          else
            begin
              socket = Socket.new(Socket::AF_UNIX, Socket::SOCK_DGRAM, 0)
              socket.connect(Socket.pack_sockaddr_un(@path))
              socket.sendmsg(Marshal.dump(message))
            ensure
              socket.close
            end
          end
        end
      end

      def listen
        Pakyow.async { |task|
          receive

          while running?
            until @messages.empty?
              message = @messages.shift
              yield message[:event], **message[:payload]
            end

            break unless running?

            @notification.wait
          end
        }.wait
      end

      def stop
        return unless running?

        @notification.signal

        Pakyow.async {
          @socket.close
        }.wait

        if File.exist?(@path)
          FileUtils.rm(@path)
        end

        @socket = nil
        @endpoint = nil
      end

      def running?
        File.exist?(@path)
      end

      private def receive
        Pakyow.async do
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
