# frozen_string_literal: true

module Pakyow
  module Data
    class Command
      def initialize(block, source:)
        @block, @source = block, source
      end

      def call(values)
        if dataset = @source.instance_exec(values, &@block)
          @source.dup.tap { |source|
            source.__setobj__(dataset)
          }
        end
      end
    end
  end
end
