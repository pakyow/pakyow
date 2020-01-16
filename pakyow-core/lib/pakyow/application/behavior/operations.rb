# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/operation"

module Pakyow
  class Application
    module Behavior
      # Adds support for operations.
      #
      module Operations
        extend Support::Extension

        apply_extension do
          after :make do
            definable :operation, Operation, lookup: -> (app, operation, **values, &block) {
              (block ? Class.new(operation, &block) : operation).new(app: app, **values).perform
            }

            aspect :operations
          end
        end
      end
    end
  end
end
