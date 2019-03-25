# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module PlaceInMode
        extend Support::Extension

        apply_extension do
          build do |app, view, mode|
            if mode == :default
              mode = view.info(:mode) || mode
            end

            if mode
              mode = mode.to_sym
              view.object.each_significant_node(:mode).select { |node|
                node.label(:mode) != mode
              }.each(&:remove)
            end
          end
        end
      end
    end
  end
end
