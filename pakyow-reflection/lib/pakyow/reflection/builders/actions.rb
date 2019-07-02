# frozen_string_literal: true

require "pakyow/reflection/builders/abstract"
require "pakyow/reflection/builders/helpers/controller"

module Pakyow
  module Reflection
    module Builders
      class Actions < Abstract
        include Helpers::Controller

        def build(actions)
          actions.each do |action|
            define_action(action)
          end
        end

        private

        def define_action(action)
          if action.parents.any?
            parents = action.parents.dup

            current_resource = ensure_controller_has_helpers(
              find_or_define_resource_for_scope_at_path(parents.shift, action.view_path)
            )

            parents.each do |parent|
              current_resource = ensure_controller_has_helpers(
                find_or_define_resource_for_scope_in_resource(parent, current_resource)
              )
            end

            resource = find_or_define_resource_for_scope_in_resource(action.scope, current_resource)
          else
            resource = find_or_define_resource_for_scope_at_path(action.scope, action.view_path)
          end

          ensure_controller_has_helpers(resource)

          # Define the route unless it exists.
          #
          # Actions are easy since they always go in the resource controller for
          # the scope. If a nested scope, the action is defined on the nested
          # resource returned by `find_or_define_resource_for_scope`.
          #
          route = resource.routes.values.flatten.find { |possible_route|
            possible_route.name == action.name
          } || resource.send(action.name) do
            reflect
          end

          # Install the reflect action if it hasn't been installed for this route.
          #
          if route.name
            unless action.node.labeled?(:endpoint)
              form_endpoint_name = [resource.name_of_self.to_s, route.name.to_s].join("_").to_sym
              action.node.significance << :endpoint
              action.node.set_label(:endpoint, form_endpoint_name)
              action.node.attributes[:"data-e"] = form_endpoint_name
            end

            resource.action :set_reflected_action, only: [route.name] do
              if connection.form
                form_view_path = connection.form[:view_path]
                form_binding = connection.form[:binding]&.to_sym

                connection.set(:__reflected_action, action.scope.actions.find { |possible_action|
                  possible_action.view_path == form_view_path && possible_action.binding == form_binding
                })
              end
            end
          else
            # TODO: warn the user that a reflection couldn't be installed for an unnamed route
          end
        end
      end
    end
  end
end
