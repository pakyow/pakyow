# frozen_string_literal: true

require "json"

require "pakyow/logger/timekeeper"

module Pakyow
  class Logger
    module Formatters
      # Formats log messages as json.
      #
      # @example
      #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"0.01ms","method":"GET","path":"/","ip":"127.0.0.1"}
      #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"1.24ms","message":"hello 2016-06-20 10:07:30 -0500"}
      #   {"severity":"INFO","timestamp":"2016-06-20 10:07:30 -0500","id":"c8af6a8b","type":"http","elapsed":"3.08ms","status":200}
      #
      # @api private
      class JSON
        def call(severity, datetime, _progname, message)
          format(
            {
              severity: severity,
              timestamp: datetime
            }.merge(ensure_hash(message))
          )
        end

        # @api private
        def format_prologue(connection)
          {
            method: connection.method.to_s.upcase,
            uri: connection.path,
            ip: connection.ip
          }
        end

        # @api private
        def format_epilogue(connection)
          {
            status: connection.status
          }
        end

        # @api private
        def format_message(message, id:, type:, elapsed:)
          {
            id: id,
            type: type,
            elapsed: Timekeeper.format_elapsed_time_in_milliseconds(
              elapsed
            ),
          }.merge(ensure_hash(message))
        end

        # @api private
        def format_error(error)
          {
            exception: error.class,
            message: error.to_s,
            backtrace: error.backtrace
          }
        end

        private

        def format(message)
          message = case message
          when Exception
            format_error(message)
          else
            message
          end

          message.to_json + "\n"
        end

        def ensure_hash(message)
          case message
          when Hash
            message
          else
            { message: message.to_s }
          end
        end
      end
    end
  end
end
