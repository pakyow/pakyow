# frozen_string_literal: true

require "pakyow/support/hookable"

require "pakyow/routing/security/errors"

module Pakyow
  module Security
    class Base
      include Support::Hookable
      known_events :reject

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
          logger(connection)&.warn "Request rejected by #{self.class}; env: #{loggable_env(connection.request.env).inspect}"

          connection.status = 403
          connection.set_response_header("Content-Type", "text/plain")
          connection.body = ["Forbidden"]

          raise InsecureRequest
        end
      end

      def logger(connection)
        connection.env["rack.logger"]
      end

      def safe?(connection)
        SAFE_HTTP_METHODS.include? connection.method
      end

      def allowed?(_)
        false
      end

      protected

      def loggable_env(env)
        env.delete("puma.config"); env
      end
    end
  end
end
