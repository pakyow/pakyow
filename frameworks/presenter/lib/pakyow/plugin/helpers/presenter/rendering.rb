# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class Plugin
    module Helpers
      module Presenter
        module Rendering
          extend Support::Extension

          prepend_methods do
            def render(view_path = nil, as: nil, modes: [:default])
              super(view_path, as: as, modes: modes)
            rescue Pakyow::Presenter::UnknownPage
              # Try rendering the view from the app.
              #
              connection = @connection.app.parent.isolated(:Connection).from_connection(
                @connection, :@app => @connection.app.parent
              )

              connection.render(view_path, as: as, modes: modes)
            end
          end
        end
      end
    end
  end
end
