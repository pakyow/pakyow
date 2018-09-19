# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/makeable"
require "pakyow/support/safe_string"

require "pakyow/helpers/connection"

module Pakyow
  class App
    module Helper
      extend Support::Makeable
    end

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

          before :load do
            # Helpers are loaded first so that other aspects inherit them.
            #
            load_app_aspect(File.join(config.src, "helpers"), :helpers)

            self.class.state(:helper).each do |helper|
              context = if helper.instance_variable_defined?(:@type)
                helper.instance_variable_get(:@type)
              else
                :global
              end

              self.class.register_helper(context, helper)
            end
          end
        end

        class_methods do
          # Define helpers as stateful when an app is defined.
          #
          def make(*)
            super.tap do |new_class|
              new_class.stateful :helper, Helper
            end
          end

          # Registers a helper module to be loaded on defined endpoints.
          #
          def register_helper(context, helper_module)
            (config.helpers[context.to_sym] << helper_module).uniq!
          end

          # Includes helpers for a context into an isolated class. Global helpers
          # will automatically be included into active and passive contexts, and
          # passive helpers will automatically be included into the active context.
          #
          def include_helpers(context, isolated_class_name)
            helpers(context.to_sym).each do |helper|
              isolated(isolated_class_name).include helper
            end
          end

          def helpers(context)
            case context.to_sym
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
