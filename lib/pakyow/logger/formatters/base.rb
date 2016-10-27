module Pakyow
  module Logger
    # @abstract
    # @api private
    class BaseFormatter
      def call(severity, datetime, progname, message)
        message.is_a?(Hash) ? message : { message: message }
      end

      private

      def format_message(message)
        if message.key?(:prologue)
          format_prologue(message)
        elsif message.key?(:epilogue)
          format_epilogue(message)
        elsif message.key?(:error)
          format_error(message)
        else
          message
        end
      end
    end
  end
end
