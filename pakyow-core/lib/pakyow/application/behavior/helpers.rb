# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/safe_string"

require "pakyow/helper"

require "pakyow/application/helpers/app"
require "pakyow/application/helpers/connection"

module Pakyow
  class Application
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
                    Pakyow::Application::Helpers::Application,
                    Support::SafeStringHelpers
                  ],

                  passive: [
                    Pakyow::Application::Helpers::Connection
                  ],

                  active: []

          after "make", priority: :high do
            definable :helper, Helper

            aspect :helpers
          end

          after "load" do
            helpers.each do |helper|
              context = if helper.instance_variable_defined?(:@type)
                helper.instance_variable_get(:@type)
              else
                :global
              end

              register_helper(context, helper)
            end
          end
        end

        class_methods do
          # Register a helper module for `context`.
          #
          def register_helper(context, helper_module)
            (config.helpers[context.to_sym] << helper_module).uniq!
          end

          # Includes helpers of a particular `context` into `object`. Global helpers
          # will automatically be included into active and passive contexts, and
          # passive helpers will automatically be included into the active context.
          #
          def include_helpers(context, object)
            @__included_helpers[object] = context

            helpers_for_context(context.to_sym).each do |helper|
              object.include helper
            end
          end

          # @api private
          def helpers_for_context(context)
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
