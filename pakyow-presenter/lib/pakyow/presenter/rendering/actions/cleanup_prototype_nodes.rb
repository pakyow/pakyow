# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module CleanupPrototypeNodes
        extend Support::Extension

        apply_extension do
          build do |view|
            unless Pakyow.env?(:prototype)
              view.object.each_significant_node(:prototype, descend: true).map(&:itself).each(&:remove)
            end
          end
        end
      end
    end
  end
end
