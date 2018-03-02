# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Modes
        extend Support::Extension

        def place_in_mode(mode)
          mode = mode.to_s

          modes = @view.info(:modes).to_h

          if mode == "default"
            mode = modes["default"]
          end

          if instructions = modes[mode]
            instructions["conceal"].to_a.each do |instruction|
              type, name, version = instruction.split(".").map(&:to_sym)
              type = :component if type == :ui

              @view.object.find_significant_nodes_with_name(type, name).each do |node|
                if !version || (version && node.label(:version) == version)
                  node.remove
                end

                node.delete_label(:version) if version
              end
            end

            instructions["display"].to_a.each do |instruction|
              type, name, version = instruction.split(".").map(&:to_sym)
              type = :component if type == :ui

              @view.object.find_significant_nodes_with_name(type, name).each do |node|
                if version && node.label(:version) != version
                  node.remove
                end

                node.delete_label(:version) if version
              end
            end
          end
        end
      end
    end
  end
end
