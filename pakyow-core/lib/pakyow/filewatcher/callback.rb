# frozen_string_literal: true

module Pakyow
  class Filewatcher
    # @api private
    class Callback
      def initialize(matcher, snapshot: false, &block)
        @matcher = normalize_matcher(matcher)
        @snapshot = !!snapshot
        @block = block
      end

      def matches?(path)
        case @matcher
        when NilClass
          true
        when String
          @matcher == path
        else
          @matcher.match?(path)
        end
      end

      def snapshot?
        @snapshot == true
      end

      def call(*args)
        @block.call(*args)
      end

      private def normalize_matcher(matcher)
        case matcher
        when NilClass, Regexp
          matcher
        else
          File.expand_path(matcher.to_s)
        end
      end
    end
  end
end
