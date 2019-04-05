# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module CleanupUnusedNodes
        extend Support::Extension

        apply_extension do
          attach do |presenter|
            unless Pakyow.env?(:prototype)
              # Remove unused bindings. We don't do this in prototype mode because it's important
              # for the prototype to be complete, showing everything to the designer.
              #
              presenter.render node: -> {
                object.find_significant_nodes(:binding).map { |node|
                  View.from_object(node)
                }
              }, priority: :low do
                # We check that the node is still labeled as a binding in case the node was replaced
                # during a previous transformation with a node that isn't a binding.
                #
                unless !view.object.labeled?(:binding) || view.object.labeled?(:used) || view.object.labeled?(:failed)
                  remove
                end
              end
            end

            # Remove unused versions.
            #
            presenter.render node: -> {
              object.each.select { |node|
                (node.is_a?(StringDoc::Node) && node.significant? && node.labeled?(:version)) && node.label(:version) != VersionedView::DEFAULT_VERSION
              }.map { |node|
                View.from_object(node)
              }
            }, priority: :low do
              unless view.object.labeled?(:used) || view.object.labeled?(:failed)
                remove
              end
            end
          end
        end
      end
    end
  end
end
