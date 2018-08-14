# frozen_string_literal: true

require "pakyow/support/class_state"

require "pakyow/logger/request_logger"

module Pakyow
  module Middleware
    # Rack middleware used for logging during the request / response lifecycle.
    #
    class Logger
      extend Support::ClassState
      class_state :silencers, default: []

      def initialize(app)
        @app = app
      end

      def call(env)
        env[Rack::RACK_LOGGER] = Pakyow::Logger::RequestLogger.new(:http)

        if silence?(env)
          env[Rack::RACK_LOGGER].silence do
            call_with_logging(env)
          end
        else
          call_with_logging(env)
        end
      end

      private

      def call_with_logging(env)
        env[Rack::RACK_LOGGER].prologue(env)

        @app.call(env).tap do |result|
          env[Rack::RACK_LOGGER].epilogue(result)
        end
      end

      def silence?(env)
        self.class.silencers.any? { |silencer|
          silencer.call(env[Rack::PATH_INFO], env)
        }
      end
    end
  end
end
