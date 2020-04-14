# frozen_string_literal: true

require "forwardable"

require_relative "../logger"

module Pakyow
  class Logger
    # Determines at log time what logger to use, based on a thread-local context.
    #
    class ThreadLocal
      def initialize(default_logger, key: nil)
        if key.nil?
          Pakyow.deprecated "default value for `#{self.class}' argument `key'", solution: "pass value for `key'"

          key = :pakyow_logger
        end

        @default, @key = default_logger, key
      end

      def target
        Thread.current[@key] || @default
      end

      def set(logger)
        Thread.current[@key] = logger
      end

      def replace(logger)
        @default = logger
      end

      def silence(temporary_level = :error)
        current = Thread.current[@key]

        logger = target.dup
        logger.level = temporary_level
        Thread.current[@key] = logger

        yield

        Thread.current[@key] = current
      end

      extend Forwardable
      def_delegators :target, *(Logger.instance_methods - instance_methods)
    end
  end
end
