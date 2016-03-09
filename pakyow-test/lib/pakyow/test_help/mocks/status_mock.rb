module Pakyow
  module TestHelp
    class MockStatus
      attr_reader :value

      def initialize(value)
        @value = value
      end

      def ==(equal_value)
        if equal_value.is_a?(Symbol)
          equal_value = Pakyow::Response::STATUS_CODE_LOOKUP[equal_value]
        end

        @value == equal_value
      end

      def to_i
        @value
      end
    end
  end
end
