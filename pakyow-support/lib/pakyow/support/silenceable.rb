# frozen_string_literal: true

module Pakyow
  module Support
    # Silence warnings.
    #
    module Silenceable
      def self.silence_warnings
        original_verbosity = $VERBOSE
        $VERBOSE = nil
        yield
      ensure
        $VERBOSE = original_verbosity
      end

      def silence_warnings(&block)
        Silenceable.silence_warnings(&block)
      end
    end
  end
end
