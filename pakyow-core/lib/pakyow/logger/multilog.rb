# frozen_string_literal: true

module Pakyow
  class Logger
    # Log to multiple targets.
    #
    class MultiLog
      attr_reader :targets

      def initialize(*targets)
        @targets = targets.map { |target|
          case target
          when String
            File.open(target)
          else
            target
          end
        }
      end

      def write(*args)
        @targets.each do |target|
          target.write(*args)
        end
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
