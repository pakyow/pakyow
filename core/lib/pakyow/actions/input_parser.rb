# frozen_string_literal: true

module Pakyow
  module Actions
    # Parses the request body with registered parsers.
    #
    class InputParser
      def call(connection)
        if (parser = parser(connection)) && (input = connection.input) && !input.empty?
          connection.input_parser = parser
        end
      end

      private

      def parser(connection)
        Pakyow.input_parsers[connection.type]
      end
    end
  end
end
