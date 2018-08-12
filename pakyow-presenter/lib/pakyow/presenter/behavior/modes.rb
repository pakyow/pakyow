# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Modes
        extend Support::Extension

        def place_in_mode(mode)
          if mode == :default
            mode = @view.info(:mode)
          end

          if mode
            mode = mode.to_sym
            @view.object.find_significant_nodes(:mode).each do |node|
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
