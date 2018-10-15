# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallComponents
        def initialize(_options)
        end

        def call(renderer)
          if renderer.connection.app.config.presenter.ui.navigable
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
end
