# frozen_string_literal: true

module Pakyow
  class Logger
    # Helpers for formatting elapsed time in logs.
    #
    module Timekeeper
      # Accepts elapsed time and formats it to be more human-readable.
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format_elapsed_time(60)
      #   => 1.00m
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format_elapsed_time(15)
      #   => 15.00s
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format_elapsed_time(0.1)
      #   => 100.00ms
      #
      # @example
      #   Pakyow::Logger::Timekeeper.format_elapsed_time(0.00001)
      #   => 10.00μs
      #
      # @param time [Fixnum, Float] the elapsed time (in seconds)
      #
      # @return [String] elapsed time, rounded to two decimal places
      #   with the proper units
      #
      def self.format_elapsed_time(time)
        if time >= 60
          format_elapsed_time_in_minutes(time)
        elsif time >= 1
          format_elapsed_time_in_seconds(time)
        elsif time >= 0.001
          format_elapsed_time_in_milliseconds(time)
        else
          format_elapsed_time_in_microseconds(time)
        end
      end

      def self.format_elapsed_time_in_minutes(time)
        round_elapsed_time(time / 60).to_s + "m "
      end

      def self.format_elapsed_time_in_seconds(time)
        round_elapsed_time(time).to_s + "s "
      end

      def self.format_elapsed_time_in_milliseconds(time)
        round_elapsed_time(time * 1_000).to_s + "ms"
      end

      def self.format_elapsed_time_in_microseconds(time)
        round_elapsed_time(time * 1_000_000).to_s + "μs"
      end

      def self.round_elapsed_time(time)
        "%.2f" % time
      end
    end
  end
end
