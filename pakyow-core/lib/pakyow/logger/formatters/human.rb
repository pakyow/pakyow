# frozen_string_literal: true

require "log4r"

require "pakyow/connection"
require "pakyow/error"

require "pakyow/logger/colorizer"
require "pakyow/logger/timekeeper"

require "pakyow/connection/statuses"

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
      class Human < Log4r::Formatter
        def format(event)
          entry = String.new

          case event.data
          when Hash
            if event.data.key?(:logger) && event.data.key?(:message)
              format_logger_message(event.data, entry)
            else
              entry << event.data.to_s
            end
          else
            entry << event.data.to_s
          end

          Colorizer.colorize(entry, event.level) << "\n"
        end

        private

        def format_logger_message(logger_message, entry)
          logger, message = logger_message.values_at(:logger, :message)

          format_info(entry, id: logger.id, type: logger.type, elapsed: logger.elapsed)

          case message
          when Hash
            if connection = message[:prologue]
              format_prologue(connection, entry)
            elsif connection = message[:epilogue]
              format_epilogue(connection, entry)
            elsif error = message[:error]
              format_error(error, entry)
            else
              format_message(message, entry)
            end
          when Exception
            format_error(message, entry)
          else
            format_message(message, entry)
          end
        end

        def format_prologue(connection, entry)
          entry << connection.request_method << " " << connection.path
          entry << " (for " << connection.ip << " at " << connection.timestamp.to_s << ")"
        end

        def format_epilogue(connection, entry)
          entry << connection.status.to_s << " (" << Connection::Statuses.describe(connection.status) << ")"
        end

        def format_info(entry, id:, type:, elapsed:)
          entry << Timekeeper.format_elapsed_time(elapsed).rjust(8, " ")
          entry << " " << type.to_s << "." << id << " | "
        end

        def format_message(message, entry)
          message.to_s.each_line.with_index do |line, i|
            if i == 0
              entry << line.rstrip
            else
              entry << "\n                       | " << line.rstrip
            end
          end
        end

        def format_error(error, entry)
          unless error.is_a?(Error)
            error = Error.build(error)
          end

          format_message(Error::CLIFormatter.new(error), entry)
        end
      end
    end
  end
end
