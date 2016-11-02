require "pakyow/logger/formatters/base"
require "pakyow/logger/colorizer"
require "pakyow/logger/timekeeper"
require "pakyow/response"

module Pakyow
  module Logger
    # Used by {Pakyow::Logger::RequestLogger} to format request / response lifecycle messages for development.
    #
    # @example
    #   19.00μs http.c730cb72 | GET / (for 127.0.0.1 at 2016-06-20 10:00:49 -0500)
    #    1.97ms http.c730cb72 | hello 2016-06-20 10:00:49 -0500
    #    3.78ms http.c730cb72 | 200 (OK)
    #
    # @api private
    class DevFormatter < BaseFormatter
      def call(severity, datetime, progname, message)
        message = format_message(super)
        Colorizer.colorize(format(message), severity)
      end

      private

      def format_prologue(message)
        prologue = message.delete(:prologue)
        message.merge(message: sprintf(
          "%s %s (for %s at %s)",
          prologue[:method],
          prologue[:uri],
          prologue[:ip],
          prologue[:time]
        ))
      end

      def format_epilogue(message)
        epilogue = message.delete(:epilogue)
        message.merge(message: sprintf(
          "%s (%s)",
          epilogue[:status],
          Response.nice_status(epilogue[:status])
        ))
      end

      def format_error(message)
        error = message.delete(:error)
        message.merge(message: sprintf(
          "%s: %s\n%s",
          error[:exception],
          error[:message],
          error[:backtrace].join("\n")
        ))
      end

      def format(message)
        return message[:message] + "\n" unless message.key?(:request)

        sprintf(
          "%s %s.%s | %s\n",
          Timekeeper.format(message[:elapsed]).rjust(8, " "),
          message[:request][:type],
          message[:request][:id],
          message[:message]
        )
      end
    end
  end
end
