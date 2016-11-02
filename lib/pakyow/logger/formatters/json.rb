require "json"

require "pakyow/logger/formatters/base"
require "pakyow/logger/timekeeper"

module Pakyow
  module Logger
    # Used by {Pakyow::Logger::RequestLogger} to format request / response lifecycle messages as JSON.
    #
    # @example
    #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"0.01ms","method":"GET","path":"/","ip":"127.0.0.1"}
    #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"1.24ms","message":"hello 2016-06-20 10:07:30 -0500"}
    #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"3.08ms","status":200}
    #
    # @api private
    class JSONFormatter < BaseFormatter
      def call(severity, datetime, progname, message)
        message = super
        message = format_message(message)

        if message.key?(:elapsed)
          message[:elapsed] = Timekeeper.format_in_milliseconds(message[:elapsed])
        end

        request = message.delete(:request)
        message = request.merge(message) if request

        format({
          severity: severity,
          timestamp: datetime
        }.merge(message))
      end

      private

      def format_prologue(message)
        prologue = message.delete(:prologue)
        message.merge(prologue)
      end

      def format_epilogue(message)
        epilogue = message.delete(:epilogue)
        message.merge(epilogue)
      end

      def format_error(message)
        error = message.delete(:error)
        message.merge(error)
      end

      def format(message)
        message.delete(:time)
        message.to_json + "\n"
      end
    end
  end
end
