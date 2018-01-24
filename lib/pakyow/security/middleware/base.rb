# frozen_string_literal: true

require "pakyow/support/hookable"
require "pakyow/support/configurable"

module Pakyow
  module Security
    module Middleware
      class Base
        include Support::Hookable
        known_events :reject

        include Support::Configurable

        SAFE_HTTP_METHODS = %w[GET HEAD OPTIONS TRACE].freeze

        def initialize(app, **options)
          @app = app
          use_config(Pakyow.env || :production)
          set_config_options(options)
        end

        def call(env)
          if safe?(env) || allowed?(env)
            @app.call(env)
          else
            reject(env)
          end
        end

        def reject(env)
          performing :reject do
            logger(env)&.warn "Request rejected by #{self.class}; env: #{loggable_env(env).inspect}"
            [403, { "Content-Type" => "text/plain" }, ["Forbidden"]]
          end
        end

        def logger(env)
          env["rack.logger"] || Pakyow.logger
        end

        def safe?(env)
          SAFE_HTTP_METHODS.include? env[Rack::REQUEST_METHOD]
        end

        def allowed?(env)
          false
        end

        protected

        def set_config_options(options, config_object = self.config)
          options.each do |key, value|
            if value.is_a?(Hash)
              set_config_options(value, config_object.public_send(key))
            else
              config_object.public_send(:"#{key}=", value)
            end
          end
        end

        def loggable_env(env)
          env.delete("puma.config"); env
        end
      end
    end
  end
end
