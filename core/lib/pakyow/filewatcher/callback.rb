# frozen_string_literal: true

module Pakyow
  class Filewatcher
    # @api private
    class Callback
      class << self
        def build(matcher, snapshot: false, &block)
          case matcher
          when ::String
            Callbacks::String.new(matcher, snapshot: snapshot, &block)
          when ::Pathname
            Callbacks::String.new(matcher.to_s, snapshot: snapshot, &block)
          when ::Regexp
            Callbacks::Regexp.new(matcher, snapshot: snapshot, &block)
          when ::NilClass
            Callbacks::NilClass.new(snapshot: snapshot, &block)
          when Callback
            matcher
          else
            raise ArgumentError, "unsure how to handle callback matcher `#{matcher}'"
          end
        end
      end

      def initialize(snapshot: false, &block)
        @snapshot = !!snapshot
        @block = block
      end

      def snapshot?
        @snapshot == true
      end

      def call(*args, **kwargs)
        @block.call(*args, **kwargs)
      end
    end

    # @api private
    module Callbacks
      class String < Callback
        def initialize(string, **kwargs, &block)
          super(**kwargs, &block)

          @string = string
        end

        def match?(path)
          @string == path
        end
      end

      class Regexp < Callback
        def initialize(regexp, **kwargs, &block)
          super(**kwargs, &block)

          @regexp = regexp
        end

        def match?(path)
          @regexp.match?(path)
        end
      end

      class NilClass < Callback
        def match?(_)
          true
        end
      end
    end
  end
end
