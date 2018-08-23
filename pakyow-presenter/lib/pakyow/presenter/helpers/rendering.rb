# frozen_string_literal: true

module Pakyow
  module Presenter
    module Helpers
      module Rendering
        def render(path = request.env["pakyow.endpoint"] || request.path, as: nil, layout: nil, mode: :default)
          renderer = app.subclass(:ViewRenderer).new(
            @connection,
            templates_path: path,
            presenter_path: as,
            layout: layout,
            mode: mode
          )

          renderer.perform

          @connection.body = StringIO.new(
            renderer.presenter.to_html(clean_bindings: !Pakyow.env?(:prototype))
          )

          @connection.rendered
        end
      end
    end
  end
end
