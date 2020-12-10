# frozen_string_literal: true

require "async/io/socket"

require "pakyow/support/deep_freeze"

module Pakyow
  module Runnable
    # Send notifications to a container from any process.
    #
    # @api private
    class Notifier
      include Support::DeepFreeze
      insulate :child, :parent

      attr_reader :child, :parent

      def initialize
        @stopped = false

        @child, @parent = Async::IO::Socket.pair(:UNIX, :DGRAM, 0)
      end


      def notify(event, **payload)
        @child&.send(Marshal.dump({event: event, payload: payload}), 0)
      rescue IOError, SystemCallError
        stop
      end

      def stop
        return unless running?

        @stopped = true

        @child.close
        @child = nil

        @parent.close
        @parent = nil
      end

      def listen
        while running? && (message = @parent&.recv(4096))
          message = Marshal.load(message)

          yield message[:event], **message[:payload]
        end
      rescue Async::Wrapper::Cancelled, SystemCallError
      ensure
        @parent&.close
      end

      private def running?
        @stopped == false
      end
    end
  end
end
