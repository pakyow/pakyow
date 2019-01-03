# frozen_string_literal: true

require "pakyow/request_logger"

module Pakyow
  module Presenter
    module Actions
      class AutoRender
        def initialize(_)
        end

        def call(connection)
          unless connection.env[Rack::RACK_LOGGER]
            connection.env[Rack::RACK_LOGGER] = RequestLogger.new(:http)
            connection.logger.prologue(connection.env)
          end

          connection.app.isolated(:ViewRenderer).perform_for_connection(connection)
        end
      end
    end
  end
end
