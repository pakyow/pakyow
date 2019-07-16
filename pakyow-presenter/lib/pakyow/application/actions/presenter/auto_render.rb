# frozen_string_literal: true

module Pakyow
  class Application
    module Actions
      module Presenter
        # Renders a view in the case a controller wasn't called.
        #
        class AutoRender
          def call(connection)
            connection.app.isolated(:Renderer).render_implicitly(connection)
          end
        end
      end
    end
  end
end
