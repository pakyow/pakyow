# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/safe_string"

require "pakyow/helpers/connection"

module Pakyow
  class App
    module Behavior
      # Maintains a list of helper modules. Helpers are either global, passive,
      # or active. Global helpers are the equivalent of utilities in that they
      # don't rely on any outside state. Passive helpers can access state on the
      # connection but aren't responsible for changing it, which active helpers
      # are solely responsible for.
      #
      module Helpers
        extend Support::Extension

        apply_extension do
          setting :helpers,
                  global: [
                    Support::SafeStringHelpers
                  ],

                  passive: [
                    Pakyow::Helpers::Connection
                  ],

                  active: []
        end

        class_methods do
          # Registers a helper module to be loaded on defined endpoints.
          #
          def helper(context, helper_module)
            (config.helpers[context] << helper_module).uniq!
          end

          # Includes helpers of a particular context into an object. Global helpers
          # will automatically be included into active and passive contexts, and
          # passive helpers will automatically be included into the active context.
          #
          def include_helpers(context, object)
            helpers(context).each do |helper|
              object.include helper
            end
          end

          def helpers(context)
            case context
            when :global
              config.helpers[:global]
            when :passive
              config.helpers[:global] + config.helpers[:passive]
            when :active
              config.helpers[:global] + config.helpers[:passive] + config.helpers[:active]
            else
              raise ArgumentError, "Unknown helper context: #{context}"
            end
          end
        end
      end
    end
  end
end
