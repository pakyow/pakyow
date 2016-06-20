module Pakyow
  module Logger
    # Helpers for formatting time in log messages.
    #
    module Timekeeper
      # Accepts elapsed time and formats it to be more human-readable.
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format(60)
      #   => 1.00m
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format(15)
      #   => 15.00s
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format(0.1)
      #   => 100.00ms
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format(0.00001)
      #   => 10.00μs
      #
      # @param time [Fixnum, Float] the elapsed time (in seconds)
      #
      # @return [String] elapsed time, rounded to two decimal places
      #   with the proper units
      #
      def self.format(time)
        if time >= 60
          format_in_minutes(time)
        elsif time >= 1
          format_in_seconds(time)
        elsif time >= 0.001
          format_in_milliseconds(time)
        else
          format_in_microseconds(time)
        end
      end

      private

      def self.format_in_minutes(time)
        round(time / 60).to_s + 'm '
      end

      def self.format_in_seconds(time)
        round(time).to_s + 's '
      end

      def self.format_in_milliseconds(time)
        round(time * 1_000).to_s + 'ms'
      end

      def self.format_in_microseconds(time)
        round(time * 1_000_000).to_s + 'μs'
      end

      def self.round(time)
        '%.2f' % time
      end
    end
  end
end
