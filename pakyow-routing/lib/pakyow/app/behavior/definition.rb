# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      module Definition
        extend Support::Extension

        apply_extension do
          include Methods
          extend Methods
        end

        module Methods
          # Defines a RESTful resource.
          #
          # @see Routing::Extension::Resource
          #
          def resources(name, path, *args, param: Pakyow::Routing::Extension::Resource::DEFAULT_PARAM, &block)
            controller name, path, *args do
              expand_within(:resources, param: param, &block)
            end
          end

          # Registers an error handler automatically available in all Controller instances.
          #
          # @see Routing::Behavior::ErrorHandling#handle
          def handle(name_exception_or_code, as: nil, &block)
            const_get(:Controller).handle(name_exception_or_code, as: as, &block)
          end

          # Extends an existing controller.
          #
          # @example
          #   controller :admin, "/admin" do
          #     before :require_admin
          #
          #     def require_admin
          #       ...
          #     end
          #   end
          #
          #   extend_controller :admin do
          #     resources :posts, "/posts" do
          #       ...
          #     end
          #   end
          #
          def extend_controller(controller_name)
            if controller_name.is_a?(Support::ClassName)
              controller_name = controller_name.name
            end

            matched_controller = state(:controller).find { |controller|
              controller.__class_name.name == controller_name
            }

            if matched_controller
              matched_controller.instance_exec(&Proc.new)
            else
              fail "could not find controller named `#{controller_name}'"
            end
          end
        end
      end
    end
  end
end
