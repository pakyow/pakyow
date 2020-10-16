# frozen_string_literal: true

require "forwardable"

require "pakyow/support/thread_localizer"

require_relative "../logger"

module Pakyow
  class Logger
    # Determines at log time what logger to use, based on a thread-local context.
    #
    class ThreadLocal
      include Support::ThreadLocalizer

      def initialize(default_logger, key: nil)
        if key.nil?
          Pakyow.deprecated "default value for `#{self.class}' argument `key'", solution: "pass value for `key'"

          key = :pakyow_logger
        end

        @default, @key = default_logger, :"logger_thread_local_#{key}"
      end

      def target
        thread_localized(@key) || @default
      end

      def set(logger)
        thread_localize(@key, logger)
      end

      def replace(logger)
        @default = logger
      end

      def silence(temporary_level = :error)
        current = thread_localized(@key)

        logger = target.dup
        logger.level = temporary_level
        thread_localize(@key, logger)

        yield
      ensure
        thread_localize(@key, current)
      end

      extend Forwardable
      def_delegators :target, *(Logger.instance_methods - instance_methods)
    end
  end
end
