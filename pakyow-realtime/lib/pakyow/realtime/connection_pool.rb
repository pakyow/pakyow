require "nio"
require "singleton"

module Pakyow
  module Realtime
    # Manages reading from a pool of IO objects, such as WebSockets.
    #
    # Shamelessly inspired by ActionCable::Connection::StreamEventLoop.
    #
    class ConnectionPool
      include Singleton

      def initialize
        @selector = NIO::Selector.new
        @mutex = Mutex.new
        @tasks = []
      end

      # Adds a connection to the pool.
      #
      def <<(conn)
        @tasks << -> do
          monitor = @selector.register(conn.to_io, :r)
          monitor.value = conn
        end

        start
      end

      # Removes a connection from the pool.
      #
      def rm(conn)
        @tasks << -> do
          @selector.deregister(conn.to_io)
        end

        start
      end

      # Wakes up the selector (e.g. after a process fork).
      #
      def wakeup
        @selector.wakeup
      end

      private

      def start
        @mutex.synchronize do
          if @thread && @thread.alive?
            wakeup
          else
            @thread = Thread.new { run }
          end
        end
      end

      def run
        loop do
          until @tasks.empty?
            @tasks.pop.call
          end

          next unless monitors = @selector.select

          monitors.each do |monitor|
            conn = monitor.value

            begin
              conn.receive monitor.io.read_nonblock(4096)
            rescue IO::WaitReadable
              next
            rescue
              begin
                conn.shutdown
              rescue
                @selector.deregister(conn.to_io)
              end
            end
          end
        end
      end
    end
  end
end
