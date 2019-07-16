# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/safe_string"

require "pakyow/helper"

require "pakyow/helpers/app"
require "pakyow/helpers/connection"

module Pakyow
  class App
    module Behavior
      # Maintains a list of helper modules, with code for including helpers of a type into an object.
      #
      # Helpers are either global, passive, or active. Global helpers contain utility methods or
      # methods that need application-level state. Passive helpers can access state on the connection
      # but never change connection state, which active helpers are solely responsible for doing.
      #
      module Helpers
        extend Support::Extension

        apply_extension do
          class_state :__included_helpers, default: {}, inheritable: true

          setting :helpers,
                  global: [
                    Pakyow::Helpers::App,
                    Support::SafeStringHelpers
                  ],

                  passive: [
                    Pakyow::Helpers::Connection
                  ],

                  active: []

          on "load" do
            # Helpers are loaded first so that other aspects inherit them.
            #
            load_aspect(:helpers)

            self.class.state(:helper).each do |helper|
              context = if helper.instance_variable_defined?(:@type)
                helper.instance_variable_get(:@type)
              else
                :global
              end

              self.class.register_helper(context, helper)
            end
          end

          # Define helpers as stateful after an app is made.
          #
          after "make", priority: :high do
            stateful :helper, Helper
          end
        end

        class_methods do
          # Registers a helper module to be loaded on defined endpoints.
          #
          def register_helper(context, helper_module)
            (config.helpers[context.to_sym] << helper_module).uniq!
          end

          # Includes helpers of a particular context into an object. Global helpers
          # will automatically be included into active and passive contexts, and
          # passive helpers will automatically be included into the active context.
          #
          def include_helpers(context, object)
            @__included_helpers[object] = context

            helpers(context.to_sym).each do |helper|
              object.include helper
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
              raise UnknownHelperContext.new_with_message(
                context: context
              )
            end
          end

          # @api private
          def included_helper_context(object)
            @__included_helpers.each_pair do |object_with_helpers, context|
              return context if object.is_a?(object_with_helpers)
            end

            nil
          end
        end
      end
    end
  end
end
