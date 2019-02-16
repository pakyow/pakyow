# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class RenderComponents
        def call(renderer)
          unless Pakyow.env?(:prototype)
            renders = ComponentRenderer.build_recursively(
              mode: renderer.mode,
              connection: renderer.connection,
              templates_path: renderer.templates_path,
              presenter: renderer.presenter
            )

            renders.each(&:perform)
            renderer.renders.concat(renders)
          end
        end
      end
    end
  end
end
