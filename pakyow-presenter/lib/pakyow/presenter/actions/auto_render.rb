# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # Renders a view in the case a controller wasn't called.
      #
      class AutoRender
        def call(connection)
          connection.app.isolated(:ViewRenderer).perform_for_connection(connection)
        end
      end
    end
  end
end
