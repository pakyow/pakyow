# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      module Presenter
        # Performs a render if a controller is called but doesn't explicitly render.
        #
        module ImplicitRendering
          extend Support::Extension

          apply_extension do
            after :dispatch, :implicit_render do
              connection.app.isolated(:Renderer).render_implicitly(connection)
            end
          end
        end
      end
    end
  end
end
