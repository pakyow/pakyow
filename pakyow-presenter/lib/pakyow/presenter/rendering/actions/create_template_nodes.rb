# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module CreateTemplateNodes
        extend Support::Extension

        apply_extension do
          build do |view, app:|
            unless Pakyow.env?(:prototype)
              view.each_binding_scope do |node_with_binding|
                attributes = node_with_binding.attributes.attributes_hash.each_with_object({}) do |(attribute, value), acc|
                  acc[attribute] = value if attribute.to_s.start_with?("data")
                end

                node_with_binding.after("<script type=\"text/template\"#{StringDoc::Attributes.new(attributes).to_s}>#{node_with_binding}</script>")
              end
            end
          end
        end
      end
    end
  end
end
