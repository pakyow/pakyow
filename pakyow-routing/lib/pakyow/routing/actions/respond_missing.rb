# frozen_string_literal: true

module Pakyow
  module Routing
    module Actions
      class RespondMissing
        def call(connection)
          connection.app.controller_for_connection(connection).trigger(404)
        end
      end
    end
  end
end
