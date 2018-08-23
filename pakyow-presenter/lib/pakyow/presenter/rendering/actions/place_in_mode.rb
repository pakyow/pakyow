# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class PlaceInMode
        def initialize(_options)
        end

        def call(renderer)
          mode = renderer.mode

          if mode == :default
            mode = renderer.presenter.view.info(:mode)
          end

          if mode
            mode = mode.to_sym
            renderer.presenter.view.object.find_significant_nodes(:mode).each do |node|
              unless node.label(:mode) == mode
                node.remove
              end
            end
          end
        end
      end
    end
  end
end
