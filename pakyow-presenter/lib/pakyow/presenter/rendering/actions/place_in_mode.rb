# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class PlaceInMode
        def call(renderer)
          mode = renderer.mode

          if mode == :default
            mode = renderer.presenter.view.info(:mode)
          end

          if mode
            mode = mode.to_sym
            renderer.presenter.view.object.each_significant_node(:mode).select { |node|
              node.label(:mode) != mode
            }.each(&:remove)
          end
        end
      end
    end
  end
end
