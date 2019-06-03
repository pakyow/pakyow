# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/composers/component"

module Pakyow
  module Presenter
    module Actions
      module Componentize
        extend Support::Extension

        apply_extension do
          build do |view, app:, composer:, mode:|
            if app.config.presenter.componentize
              view.object.each_significant_node(:form) do |form|
                form.instance_variable_get(:@significance) << :component
                form.attributes[:"data-ui"] = :form
                form.set_label(:component, :form)
              end

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
  end
end
