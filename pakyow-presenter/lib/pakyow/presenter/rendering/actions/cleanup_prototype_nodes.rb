# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class CleanupPrototypeNodes
        def call(renderer)
          unless renderer.rendering_prototype?
            renderer.presenter.view.object.each_significant_node(:prototype).map(&:itself).each(&:remove)
          end
        end
      end
    end
  end
end
