# frozen_string_literal: true

require "json"

require "pakyow/logger"
require "pakyow/logger/timekeeper"

module Pakyow
  class Logger
    module Formatters
      # Formats log messages as json.
      #
      # @example
      #   {"severity":"info","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"0.01ms","method":"GET","path":"/","ip":"127.0.0.1"}
      #   {"severity":"info","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"1.24ms","message":"hello 2016-06-20 10:07:30 -0500"}
      #   {"severity":"info","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"3.08ms","status":200}
      #
      # @api private
      class JSON < Formatter
        private

        def format(event, options)
          entry = {
            "severity" => options[:severity],
            "timestamp" => Time.now
          }

          case event
          when Hash
            if event.key?("logger") && event.key?("message")
              format_logger_message(event, entry)
            else
              entry.merge!(event)
            end
          else
            entry["message"] = event.to_s
          end

          serialize(entry)
        end

        private

        def format_logger_message(logger_message, entry)
          logger = logger_message["logger"]
          message = logger_message["message"]

          format_entry(
            entry, id: logger.id, type: logger.type, elapsed: logger.elapsed
          )

          case message
          when Hash
            if connection = message.delete("prologue")
              format_prologue(connection, entry)
            elsif connection = message.delete("epilogue")
              format_epilogue(connection, entry)
            elsif error = message.delete("error")
              format_error(error, entry)
            else
              entry.update(message)
            end
          when Exception
            format_error(message, entry)
          else
            entry["message"] = message.to_s
          end

          serialize(
            entry
          )
        end

        def format_prologue(connection, entry)
          entry["method"] = connection.request_method
          entry["uri"] = connection.path
          entry["ip"] = connection.ip
        end

        def format_epilogue(connection, entry)
          entry["status"] = connection.status
        end

        def format_error(error, entry)
          entry["exception"] = error.class
          entry["message"] = error.to_s
          entry["backtrace"] = error.backtrace
        end

        def format_entry(entry, id:, type:, elapsed:)
          entry["id"] = id
          entry["type"] = type
          entry["elapsed"] = Timekeeper.format_elapsed_time_in_milliseconds(elapsed)
          entry
        end

        def serialize(entry)
          entry.to_json << "\n"
        end
      end
    end
  end
end
