# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module CreateTemplateNodes
          extend Support::Extension

          apply_extension do
            build do |view|
              unless Pakyow.env?(:prototype)
                view.each_binding_scope(descend: true) do |node_with_binding|
                  attributes = node_with_binding.attributes.attributes_hash.each_with_object({}) { |(attribute, value), acc|
                    acc[attribute] = value if attribute.to_s.start_with?("data")
                  }

                  node_with_binding.after("<script type=\"text/template\"#{StringDoc::Attributes.new(attributes)}>#{node_with_binding.render}</script>")
                end
              end
            end
          end
        end
      end
    end
  end
end
