# frozen_string_literal: true

require "pakyow/connection"

require "pakyow/logger/formatters/base"
require "pakyow/logger/colorizer"
require "pakyow/logger/timekeeper"

module Pakyow
  class Logger
    module Formatters
      # Used by {Pakyow::RequestLogger} to format request / response lifecycle messages for development.
      #
      # @example
      #   19.00μs http.c730cb72 | GET / (for 127.0.0.1 at 2016-06-20 10:00:49 -0500)
      #    1.97ms http.c730cb72 | hello 2016-06-20 10:00:49 -0500
      #    3.78ms http.c730cb72 | 200 (OK)
      #
      # @api private
      class Human < Formatters::Base
        def call(severity, datetime, progname, _message)
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
            Connection.nice_status(epilogue[:status])
          ))
        end

        def format_error(message)
          error = message.delete(:error)

          if error.is_a?(Pakyow::Error)
            message.merge(message: Pakyow::Error::CLIFormatter.new(error).to_s)
          else
            message.merge(message: sprintf(
              "%s: %s\n%s",
              error.class,
              error.to_s,
              error.backtrace.join("\n")
            ))
          end
        end

        def format(message)
          return message[:message] + "\n" unless message.key?(:request)

          constructed_message = sprintf(
            "%s %s.%s | %s\n",
            Timekeeper.format_elapsed_time(message[:elapsed]).rjust(8, " "),
            message[:request][:type],
            message[:request][:id],
            message[:message].lines.first.rstrip
          )

          message[:message].lines[1..-1].each_with_object(constructed_message) { |line, full|
            full << "                       | #{line.rstrip}\n"
          }
        end
      end
    end
  end
end
