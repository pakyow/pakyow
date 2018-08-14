# frozen_string_literal: true

module Pakyow
  module Logger
    # @api private
    class MultiLog
      attr_reader :targets

      def initialize(*targets)
        @targets = targets
      end

      def write(*args)
        @targets.each { |t| t.write(*args) }
      end

      def close
        @targets.each(&:close)
      end

      def flush
        @targets.each(&:flush)
      end
    end
  end
end
