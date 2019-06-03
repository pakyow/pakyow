# frozen_string_literal: true

module Pakyow
  class Logger
    class Destination
      attr_reader :name, :io

      def initialize(name, io)
        @name, @io = name, io
      end

      def call(entry)
        @io.write(entry)
      end
    end
  end
end
