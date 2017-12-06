# frozen_string_literal: true

require "nio"
require "concurrent/array"

module Pakyow
  module Realtime
    # Manages reading from a pool of IO objects, such as WebSockets.
    #
    # Heavily inspired by ActionCable::Connection::StreamEventLoop.
    # Copyright (c) 2015-2017 Basecamp, LLC
    class EventLoop
      def initialize
        @mutex = Mutex.new
        @selector = NIO::Selector.new
        @tasks = Concurrent::Array.new
      end

      # Adds a connection to the pool.
      #
      def <<(connection)
        @tasks << -> do
          monitor = @selector.register(connection.to_io, :r)
          monitor.value = connection
        end

        start
      end

      # Removes a connection from the pool.
      #
      def rm(connection)
        @tasks << -> do
          @selector.deregister(connection.to_io)
        end

        start
      end

      private

      def wakeup
        @selector.wakeup
      end

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
            connection = monitor.value

            begin
              connection.receive(monitor.io.read_nonblock(4096))
            rescue IO::WaitReadable
              next
            rescue
              begin
                connection.shutdown
              rescue
                @selector.deregister(connection.to_io)
              end
            end
          end
        end
      end
    end
  end
end
