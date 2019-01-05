# frozen_string_literal: true

require "pakyow/support/pipelined"

module Pakyow
  module Presenter
    module Pipelines
      # Performs a render if a controller is called but doesn't explicitly render.
      #
      module ImplicitRendering
        extend Support::Pipelined::Pipeline

        action :setup_for_implicit_rendering

        protected

        def setup_for_implicit_rendering(connection)
          connection.on :finalize do
            app.isolated(:ViewRenderer).perform_for_connection(self)
          end
        end
      end
    end
  end
end
