# frozen_string_literal: true

require "forwardable"

require "pakyow/support/deep_freeze"

require "pakyow/logger"

module Pakyow
  class Logger
    # Determines at log time what logger to use, based on a thread-local context.
    #
    class ThreadLocal
      extend Support::DeepFreeze
      insulate :default

      extend Forwardable
      def_delegators :target, *(Logger.instance_methods - Object.instance_methods)

      def initialize(default_logger)
        @default = default_logger
      end

      def target
        Thread.current[:pakyow_logger] || @default
      end

      def replace(logger)
        @default = logger
      end
    end
  end
end
