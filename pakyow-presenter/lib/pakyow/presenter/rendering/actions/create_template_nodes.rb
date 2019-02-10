# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class CreateTemplateNodes
        def call(renderer)
          if !renderer.rendering_prototype? && renderer.embed_templates?
            renderer.presenter.view.each_binding_scope do |node_with_binding|
              attributes = node_with_binding.attributes.attributes_hash.each_with_object({}) do |(attribute, value), acc|
                next unless attribute.to_s.start_with?("data")
                acc[attribute] = value
              end

              attributes = StringDoc::Attributes.new(attributes).to_s
              template = String.new("<script type=\"text/template\"#{attributes}>#{node_with_binding}</script>")
              node_with_binding.after(template)
            end
          end
        end
      end
    end
  end
end
