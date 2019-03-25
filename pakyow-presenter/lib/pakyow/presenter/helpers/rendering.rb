# frozen_string_literal: true

module Pakyow
  module Presenter
    module Helpers
      module Rendering
        def render(view_path = nil, as: nil, mode: :default)
          @connection.app.isolated(:Renderer).render(
            @connection,
            view_path: view_path,
            presenter_path: as,
            mode: mode
          )
        end
      end
    end
  end
end
