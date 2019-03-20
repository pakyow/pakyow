# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class RenderComponents
        def call(renderer)
          unless Pakyow.env?(:prototype)
            initial_component_path = case self
            when ComponentRenderer
              @component_path
            else
              []
            end

            renderer.presenter.components(renderable: true).each_with_index do |component_presenter, i|
              ComponentRenderer.build(
                name: component_presenter.view.object.label(:component),
                path: initial_component_path.dup << i,
                mode: renderer.mode,
                connection: renderer.connection,
                templates_path: renderer.templates_path,
                presenter: component_presenter
              ).perform
            end
          end
        end
      end
    end
  end
end
