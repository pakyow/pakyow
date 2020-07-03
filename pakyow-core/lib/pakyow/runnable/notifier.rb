# frozen_string_literal: true

module Pakyow
  module Runnable
    # Send notifications to a container from any process.
    #
    # @api private
    class Notifier
      def initialize(**callback_options, &callback)
        @callback_options, @callback = callback_options, callback
        @child, @parent = Socket.pair(:UNIX, :DGRAM, 0)
        @thread = nil
        @running = true

        run
      end

      attr_reader :child, :parent

      def notify(event, **payload)
        @child.send(Marshal.dump({ event: event, payload: payload }), 0)
      end

      def stop
        @running = false
        @child.close
      end

      private def run
        @thread = Thread.new do
          while running? && message = @parent.recv(4096)
            message = Marshal.load(message)

            @callback.call(message[:event], message[:payload].merge(@callback_options))
          end
        end
      end

      private def running?
        @running == true
      end
    end
  end
end
