# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallComponents
        def initialize(_options)
        end

        def call(renderer)
          if renderer.connection.app.config.presenter.componentize
            install_forms(renderer)
            install_navigator(renderer)
          end
        end

        private

        def install_forms(renderer)
          renderer.presenter.view.object.find_significant_nodes(:form).each do |form|
            form.instance_variable_get(:@significance) << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end

        def install_navigator(renderer)
          if html = renderer.presenter.view.object.find_significant_nodes(:html)[0]
            html.instance_variable_get(:@significance) << :component
            html.attributes[:"data-ui"] = :navigable
            html.set_label(:component, :navigable)
          end
        end
      end
    end
  end
end
