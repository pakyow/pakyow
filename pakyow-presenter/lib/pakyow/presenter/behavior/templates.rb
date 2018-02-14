# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Templates
        extend Support::Extension

        def create_template_nodes
          @view.binding_scopes.each do |node_with_binding|
            version = node_with_binding.label(:version) || VersionedView::DEFAULT_VERSION
            template = StringDoc.new("<script type=\"text/template\" data-version=\"#{version}\"></script>").nodes.first

            node_with_binding.attributes.each do |attribute, value|
              next unless attribute.to_s.start_with?("data")
              template.attributes[attribute] = value
            end

            duped_node_with_binding = node_with_binding.dup
            duped_node_with_binding.with_children.each do |node|
              node.instance_variable_set(:@type, nil)
              node.instance_variable_set(:@name, nil)
            end
            template.append(duped_node_with_binding)
            node_with_binding.after(template)
          end
        end
      end
    end
  end
end
