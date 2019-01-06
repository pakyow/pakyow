# frozen_string_literal: true

require "pakyow/connection"
require "pakyow/error"

require "pakyow/logger/colorizer"
require "pakyow/logger/timekeeper"

module Pakyow
  class Logger
    module Formatters
      # Formats log messages for humans.
      #
      # @example
      #   19.00μs http.c730cb72 | GET / (for 127.0.0.1 at 2016-06-20 10:00:49 -0500)
      #    1.97ms http.c730cb72 | hello 2016-06-20 10:00:49 -0500
      #    3.78ms http.c730cb72 | 200 (OK)
      #
      # @api private
      class Human
        def call(severity, _datetime, _progname, message)
          message = case message
          when Exception
            format_error(message)
          else
            message
          end

          Colorizer.colorize(message, severity)
        end

        # @api private
        def format_prologue(connection)
          sprintf(
            "%s %s (for %s at %s)",
            connection.method.to_s.upcase,
            connection.path,
            connection.ip,
            connection.timestamp
          )
        end

        # @api private
        def format_epilogue(connection)
          sprintf(
            "%s (%s)",
            connection.status,
            Connection.nice_status(connection.status)
          )
        end

        # @api private
        def format_message(message, id:, type:, elapsed:)
          constructed_message = sprintf(
            "%s %s.%s | %s\n",
            Timekeeper.format_elapsed_time(elapsed).rjust(8, " "),
            type, id, message.lines.first.rstrip
          )

          message.lines[1..-1].each_with_object(constructed_message) { |line, full|
            full << "                       | #{line.rstrip}\n"
          }
        end

        # @api private
        def format_error(error)
          unless error.is_a?(Error)
            error = Error.build(error)
          end

          Error::CLIFormatter.new(error).to_s
        end
      end
    end
  end
end
