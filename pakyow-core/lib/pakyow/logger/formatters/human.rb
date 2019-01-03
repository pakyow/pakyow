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
          Colorizer.colorize(message, severity)
        end

        # @api private
        def format_prologue(prologue)
          sprintf(
            "%s %s (for %s at %s)",
            prologue[:method],
            prologue[:uri],
            prologue[:ip],
            prologue[:time]
          )
        end

        # @api private
        def format_epilogue(epilogue)
          sprintf(
            "%s (%s)",
            epilogue[:status],
            Connection.nice_status(epilogue[:status])
          )
        end

        # @api private
        def format_request(id:, type:, message:, elapsed:)
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
          Error::CLIFormatter.new(error).to_s
        end
      end
    end
  end
end
