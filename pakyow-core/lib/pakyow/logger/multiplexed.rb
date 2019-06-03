# frozen_string_literal: true

module Pakyow
  class Logger
    class Multiplexed
      attr_reader :destinations

      def initialize(*destinations)
        @destinations = destinations
      end

      def call(entry)
        @destinations.each do |destination|
          destination.call(entry)
        end
      end
    end
  end
end
