# frozen_string_literal: true

require "pakyow/logger/request_logger"

module Pakyow
  module Middleware
    # Rack middleware used for logging during the request / response lifecycle.
    #
    # @api private
    class Logger
      def initialize(app)
        @app = app
      end

      def call(env)
        logger = Pakyow::Logger::RequestLogger.new(:http)
        env[Rack::RACK_LOGGER] = logger

        logger.prologue(env)
        @app.call(env).tap do |result|
          logger.epilogue(result)
        end
      end
    end
  end
end
