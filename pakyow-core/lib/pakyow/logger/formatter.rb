# frozen_string_literal: true

module Pakyow
  class Logger
    class Formatter
      attr_reader :output

      def initialize(output)
        @output = output
      end

      def call(event, **options)
        event = yield if block_given?
        @output.call(format(event, options))
      end
    end
  end
end
