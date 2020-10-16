# frozen_string_literal: true

require "pakyow/support/deprecatable"

module Pakyow
  class Application
    module Actions
      module Routing
        class RespondMissing
          extend Support::Deprecatable
          deprecate

          def call(connection)
            connection.trigger(404)
          end
        end
      end
    end
  end
end
