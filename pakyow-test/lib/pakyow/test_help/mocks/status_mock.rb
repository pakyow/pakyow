# frozen_string_literal: true

module Pakyow
  module TestHelp
    class MockStatus
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(other)
        if other.is_a?(Symbol)
          other = Pakyow::Response::STATUS_CODE_LOOKUP[other]
        end

        @value == other
      end

      def to_i
        @value
      end
    end
  end
end
