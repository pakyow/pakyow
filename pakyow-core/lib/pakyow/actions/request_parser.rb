# frozen_string_literal: true

module Pakyow
  module Actions
    # Normalizes request uris, issuing a 301 redirect to the normalized uri.
    #
    class RequestParser
      def initialize(app)
        @app = app
      end

      def call(connection)
        if (parser = parser(connection)) && (body = connection.request.body.read).length.nonzero?
          connection.parsed_body = parser.call(body)
        end
      rescue StandardError => error
        connection.logger.houston(error)
        connection.status = 400
        connection.halt
      end

      private

      def parser(connection)
        Pakyow.request_parsers[connection.request.media_type]
      end
    end
  end
end
