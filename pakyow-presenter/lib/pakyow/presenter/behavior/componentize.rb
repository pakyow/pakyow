# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Componentize
        extend Support::Extension

        prepend_methods do
          def build_view(templates_path)
            super.tap do |view|
              if config.presenter.componentize
                install_forms(view)
                install_navigator(view)
              end
            end
          end
        end

        private

        def install_forms(view)
          view.object.each_significant_node(:form) do |form|
            form.instance_variable_get(:@significance) << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end

        def install_navigator(view)
          if html = view.object.find_first_significant_node(:html)
            html.instance_variable_get(:@significance) << :component
            html.attributes[:"data-ui"] = :navigable
            html.set_label(:component, :navigable)
          end
        end
      end
    end
  end
end
