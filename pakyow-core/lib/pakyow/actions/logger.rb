# frozen_string_literal: true

module Pakyow
  module Actions
    # Sets up a connection logger and logs the prologue/epilogue.
    #
    class Logger
      def call(connection, &block)
        if silence?(connection)
          Pakyow.logger.silence do
            call_with_logging(connection, &block)
          end
        else
          call_with_logging(connection, &block)
        end
      end

      private

      def call_with_logging(connection)
        connection.logger.prologue(connection)

        finished = false

        catch :halt do
          yield

          finished = true
        end

        connection.logger.epilogue(connection)

        throw :halt unless finished
      end

      def silence?(connection)
        Pakyow.silencers.any? { |silencer|
          silencer.call(connection)
        }
      end
    end
  end
end
