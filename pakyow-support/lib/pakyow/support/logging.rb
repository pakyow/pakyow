# frozen_string_literal: true

module Pakyow
  module Support
    module Logging
      # Yields Pakyow.logger defined, otherwise raises `error`.
      #
      def self.yield_or_raise(error)
        if defined?(Pakyow.logger)
          yield(Pakyow.logger)
        else
          raise error
        end
      end
    end
  end
end
