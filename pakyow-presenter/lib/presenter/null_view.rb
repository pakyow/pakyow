module Pakyow
  module Presenter 
    class NullView
      def initialize(message)
        @message = message
      end

      def includes(*)
        self
      end

      def scope(*)
        self
      end

      def versioned?
        false
      end

      def method_missing(method, *args, &block)
        raise NoViewError.new(@message)
      end
    end

    class NoViewError < StandardError
    end
  end
end
