# frozen_string_literal: true

require "pakyow/support/hookable"

require_relative "errors"

module Pakyow
  module Security
    class Base
      include Support::Hookable
      events :reject

      SAFE_HTTP_METHODS = %i(get head options trace).freeze

      def initialize(config)
        @config = config
      end

      def call(connection)
        unless safe?(connection) || allowed?(connection)
          reject(connection)
        end

        connection
      end

      def reject(connection)
        performing :reject do
          connection.logger.warn "Request rejected by #{self.class}; connection: #{connection.inspect}"

          connection.status = 403
          connection.body = StringIO.new("Forbidden")

          raise InsecureRequest
        end
      end

      def safe?(connection)
        SAFE_HTTP_METHODS.include? connection.method
      end

      def allowed?(_)
        false
      end
    end
  end
end
