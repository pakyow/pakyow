# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module CleanupUnboundBindings
        extend Support::Extension

        apply_extension do
          attach do |presenter|
            unless Pakyow.env?(:prototype)
              # Cleanup unbound bindings. We don't do this in prototype mode because it's important
              # for the prototype to be complete, showing everything to the designer.
              #
              presenter.render node: -> {
                object.find_significant_nodes(:binding, descend: true).map { |node|
                  View.from_object(node)
                }
              }, priority: :low do
                # We check that the node is still labeled as a binding in case the node was replaced
                # during a previous transformation with a node that isn't a binding.
                #
                unless !view.object.labeled?(:binding) || view.object.labeled?(:bound) || view.object.labeled?(:failed) || view.object.label(:version) == :empty
                  remove
                end
              end
            end
          end
        end
      end
    end
  end
end
