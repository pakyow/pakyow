# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallEndpoints
        def call(renderer)
          renderer.presenter.install_endpoints(
            endpoints_for_environment(renderer),
            current_endpoint: renderer.connection.endpoint,
            setup_for_bindings: renderer.rendering_prototype?
          )
        end

        private

        # We still mark endpoints as active when running in the prototype environment, but we don't
        # want to replace anchor hrefs, form actions, etc with backend routes. This gives the designer
        # control over how the prototype behaves.
        #
        def endpoints_for_environment(renderer)
          if renderer.rendering_prototype?
            Endpoints.new
          else
            renderer.connection.app.endpoints
          end
        end
      end
    end
  end
end
