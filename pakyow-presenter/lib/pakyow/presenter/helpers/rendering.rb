# frozen_string_literal: true

module Pakyow
  module Presenter
    module Helpers
      module Rendering
        def render(path = request.env["pakyow.endpoint"] || request.path, as: nil, layout: nil, mode: :default)
          app.subclass(:Renderer).new(@connection, path: path, as: as, layout: layout, mode: mode).perform
        end
      end
    end
  end
end
