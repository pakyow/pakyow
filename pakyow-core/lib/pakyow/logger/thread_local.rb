# frozen_string_literal: true

require "forwardable"

require "pakyow/logger"

module Pakyow
  class Logger
    # Determines at log time what logger to use, based on a thread-local context.
    #
    class ThreadLocal
      def initialize(default_logger)
        @default = default_logger
      end

      def target
        Thread.current[:pakyow_logger] || @default
      end

      def replace(logger)
        @default = logger
      end

      def silence(temporary_level = :error)
        current = Thread.current[:pakyow_logger]

        logger = target.dup
        logger.level = temporary_level
        Thread.current[:pakyow_logger] = logger

        yield

        Thread.current[:pakyow_logger] = current
      end

      extend Forwardable
      def_delegators :target, *(Logger.instance_methods - instance_methods)
    end
  end
end
