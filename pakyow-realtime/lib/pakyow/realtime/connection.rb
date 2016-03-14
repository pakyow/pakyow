require_relative 'config'

module Pakyow
  module Realtime
    # Represents a realtime connection (e.g. websocket).
    #
    # @api private
    class Connection
      def delegate
        Delegate.instance
      end

      def logger
        Pakyow.logger
      end
    end
  end
end
