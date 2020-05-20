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

        run
      end

      attr_reader :child, :parent

      def notify(event, **payload)
        @child.send(Marshal.dump({ event: event, payload: payload }), 0)
      end

      def stop
        @parent.close
        @child.close
        @thread&.kill
      end

      private def run
        @thread = Thread.new do
          while message = @parent.recv(4096)
            message = Marshal.load(message)

            @callback.call(message[:event], message[:payload].merge(@callback_options))
          end
        rescue IOError
        end
      end
    end
  end
end
