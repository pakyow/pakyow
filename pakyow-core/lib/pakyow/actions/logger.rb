# frozen_string_literal: true

require "pakyow/request_logger"

module Pakyow
  module Actions
    # Sets up a connection logger and logs the prologue/epilogue.
    #
    class Logger
      def call(connection, &block)
        unless connection.pipelined?
          connection.env[Rack::RACK_LOGGER] = RequestLogger.new(
            :http, started_at: connection.timestamp, id: connection.id
          )

          if silence?(connection)
            connection.logger.silence do
              call_with_logging(connection, &block)
            end
          else
            call_with_logging(connection, &block)
          end
        end
      end

      private

      def call_with_logging(connection)
        connection.logger.prologue(connection)
        yield
        connection.logger.epilogue(connection)
      end

      def silence?(connection)
        Pakyow.silencers.any? { |silencer|
          silencer.call(connection)
        }
      end
    end
  end
end
