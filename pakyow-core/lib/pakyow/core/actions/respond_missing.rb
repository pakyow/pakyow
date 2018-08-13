# frozen_string_literal: true

module Pakyow
  module Routing
    module Actions
      class RespondMissing
        def initialize(app)
          @app = app
        end

        def call(connection)
          @app.subclass(:Controller).new(connection).trigger(404)
        end
      end
    end
  end
end
