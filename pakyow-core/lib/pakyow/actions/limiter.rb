# frozen_string_literal: true

require "protocol/http/body/wrapper"

module Pakyow
  module Actions
    # Limits the connection body to a particular size.
    #
    class Limiter
      attr_reader :length

      def initialize(length: 0)
        @length = length
      end

      def call(connection)
        connection.wrap_input do |body|
          LimitedInput.new(body, limit: @length)
        end
      end

      # @api private
      class LimitedInput < Protocol::HTTP::Body::Wrapper
        def initialize(body, limit:)
          @limit = limit

          super(body)
        end

        def read
          chunk = super

          if length && length > @limit
            raise RequestTooLarge.new_with_message(length: length, limit: @limit)
          end

          chunk
        end
      end
    end
  end
end
