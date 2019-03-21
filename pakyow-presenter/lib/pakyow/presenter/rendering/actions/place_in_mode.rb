# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class PlaceInMode
        def call(presenter)
          if presenter.respond_to?(:__mode)
            mode = presenter.__mode

            if mode == :default
              mode = presenter.view.info(:mode) || mode
            end

            if mode
              mode = mode.to_sym
              presenter.view.object.each_significant_node(:mode).select { |node|
                node.label(:mode) != mode
              }.each(&:remove)
            end
          end
        end
      end
    end
  end
end
