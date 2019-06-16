# frozen_string_literal: true

module Pakyow
  module Presenter
    module Helpers
      module Rendering
        def render(view_path = nil, as: nil, modes: [:default])
          @connection.app.isolated(:Renderer).render(
            @connection,
            view_path: view_path,
            presenter_path: as,
            modes: modes
          )
        end
      end
    end
  end
end
