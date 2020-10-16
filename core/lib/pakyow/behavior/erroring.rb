# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Erroring
      extend Support::Extension

      class_methods do
        # Reports an error, logging it through the environment logger.
        #
        # = Custom error reporting
        #
        # Register an `error` hook to report any errors that occur within Pakyow:
        #
        #   Pakyow.on :error do |error|
        #     ...
        #   end
        #
        def houston(error)
          performing(:error, error) {}
        ensure
          logger.houston(error)
        end
      end
    end
  end
end
