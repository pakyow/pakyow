# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/view"

module Pakyow
  module UI
    module Behavior
      module Rendering
        module InstallTransforms
          extend Support::Extension

          apply_extension do
            attach do |presenter|
              presenter.render node: -> {
                nodes = []

                if html_node = object.find_first_significant_node(:html)
                  nodes << Pakyow::Presenter::View.from_object(html_node)
                end

                if !object.is_a?(StringDoc) && object.significant?(:component)
                  nodes << Pakyow::Presenter::View.from_object(object)
                end

                object.each_significant_node_without_descending_into_type(:component, descend: true) do |node|
                  if node.label(:components).any? { |c| c[:renderable ] }
                    nodes << Pakyow::Presenter::View.from_object(node)
                  end
                end

                nodes
              } do
                if transformation_id = presentables[:__transformation_id]
                  # Set the transformation_id on the target node so that transformations can be applied to the right place.
                  #
                  attributes[:"data-t"] = transformation_id
                end
              end
            end
          end
        end
      end
    end
  end
end
