# frozen_string_literal: true

module Pakyow
  module Presenter
    module Actions
      # @api private
      class InstallEndpoints
        def call(presenter)
          presenter.setup_non_contextual_endpoints

          if Pakyow.env?(:prototype)
            presenter.setup_binding_endpoints({})
          end
        end
      end
    end
  end
end
