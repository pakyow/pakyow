# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class CleanupPrototypeNodes
        def call(renderer)
          unless renderer.rendering_prototype?
            renderer.presenter.view.object.find_significant_nodes(:prototype).each(&:remove)
          end
        end
      end
    end
  end
end
