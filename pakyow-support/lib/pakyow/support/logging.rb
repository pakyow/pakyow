# frozen_string_literal: true

require "logger"

module Pakyow
  module Support
    module Logging
      # Yields Pakyow.logger if defined, otherwise raises `error`.
      #
      def self.yield_or_raise(error)
        if defined?(Pakyow.logger)
          yield(Pakyow.logger)
        else
          raise error
        end
      end

      # Yields Pakyow.logger if defined, or a default logger.
      #
      def self.safe(level: nil, formatter: nil)
        logger = if defined?(Pakyow.logger) && Pakyow.logger
          Pakyow.logger
        else
          ::Logger.new($stdout).tap do |stdout_logger|
            unless level.nil?
              stdout_logger.level = level
            end

            unless formatter.nil?
              stdout_logger.formatter = formatter
            end
          end
        end

        yield logger
      end
    end
  end
end
