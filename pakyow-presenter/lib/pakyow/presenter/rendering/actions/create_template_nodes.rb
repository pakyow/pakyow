# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class CreateTemplateNodes
        def initialize(_options)
        end

        def call(renderer)
          if !renderer.rendering_prototype? && renderer.embed_templates?
            renderer.presenter.view.all_binding_scopes.each do |node_with_binding|
              template = StringDoc.new("<script type=\"text/template\"></script>").nodes.first

              node_with_binding.attributes.each do |attribute, value|
                next unless attribute.to_s.start_with?("data")
                template.attributes[attribute] = value
              end

              duped_node_with_binding = node_with_binding.dup
              duped_node_with_binding.with_children.each do |node|
                node.instance_variable_set(:@labels, {})
                node.instance_variable_set(:@significance, [])
              end
              template.append(duped_node_with_binding)
              node_with_binding.after(template)
            end
          end
        end
      end
    end
  end
end
