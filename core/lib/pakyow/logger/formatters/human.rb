# frozen_string_literal: true

require_relative "../../error"
require_relative "../../connection"
require_relative "../../connection/statuses"

require_relative "../colorizer"
require_relative "../formatter"
require_relative "../timekeeper"

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
      class Human < Formatter
        private

        def format(event, **options)
          entry = +""

          case event
          when Hash
            if event.key?("logger") && event.key?("message")
              format_logger_message(event, entry)
            else
              entry << event.to_s
            end
          else
            entry << event.to_s
          end

          @output.call(Colorizer.colorize(entry, options[:severity]) << "\n")
        end

        def format_logger_message(logger_message, entry)
          logger = logger_message["logger"]
          message = logger_message["message"]

          format_info(entry, id: logger.id, type: logger.type, elapsed: logger.elapsed)

          case message
          when Hash
            if (connection = message["prologue"])
              format_prologue(connection, entry)
            elsif (connection = message["epilogue"])
              format_epilogue(connection, entry)
            elsif (error = message["error"])
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
