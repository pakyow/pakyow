# frozen_string_literal: true

module Pakyow
  module Actions
    class Missing
      def call(connection)
        yield

        unless connection.halted? || connection.streaming?
          connection.trigger 404, connection: connection
        end
      end
    end
  end
end
