module Pakyow
  module UI
    # A simple context object used for accessing the session.
    #
    # @api private
    class UIContext
      def initialize(session)
        @session = session
      end

      def request
        UIRequest.new(@session)
      end
    end
  end
end
