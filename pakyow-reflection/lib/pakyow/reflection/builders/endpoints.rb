# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/reflection/builders/abstract"
require "pakyow/reflection/extensions/controller"

module Pakyow
  module Reflection
    module Builders
      class Endpoints < Abstract
        using Support::Refinements::String::Normalization

        def initialize(*)
          @reflected_routes = []

          super
        end

        def build(scope)
          scope.actions.each do |action|
            ensure_action_for_scope(action, scope)
          end

          scope.endpoints.each do |endpoint|
            ensure_endpoint_for_scope(endpoint, scope)
          end
        end

        private

        def ensure_action_for_scope(action, scope)
          resource = find_or_define_resource_for_scope(scope)
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
            operations.reflect(controller: self)
          end

          # Install the reflect action if it hasn't been installed for this route.
          #
          unless @reflected_routes.include?(route)
            if route.name
              resource.action :set_reflected_scope, only: [route.name] do
                connection.set(:__reflected_scope, scope)
              end

              resource.action :set_reflected_action, only: [route.name] do
                if connection.form
                  form_view_path = connection.form[:view_path]
                  form_channel = connection.form[:binding].to_s.split(":", 2)[1].to_s.split(":").map(&:to_sym)

                  connection.set(:__reflected_action, scope.actions.find { |possible_action|
                    possible_action.view_path == form_view_path && possible_action.channel == form_channel
                  })
                end
              end
            else
              # TODO: warn the user that a reflection couldn't be installed for an unnamed route
            end

            @reflected_routes << route
          end
        end

        def ensure_controller_has_helpers(controller)
          unless controller.ancestors.include?(Extension::Controller)
            controller.include Extension::Controller
          end
        end

        def ensure_endpoint_for_scope(endpoint, scope)
          controller = find_or_define_controller_for_endpoint(endpoint)
          ensure_controller_has_helpers(controller)

          route_name, route_path = if endpoint_directory?(endpoint.view_path)
            [:default, "/"]
          else
            last_endpoint_path_part = endpoint.view_path.split("/").last
            [last_endpoint_path_part.to_sym, "/#{last_endpoint_path_part}"]
          end

          if controller.expansions.include?(:resource)
            endpoint_name = String.normalize_path(
              endpoint.view_path.gsub(controller.path_to_self, "")
            ).split("/", 2)[1]

            endpoint_name = if endpoint_name.empty?
              :list
            else
              endpoint_name.to_sym
            end

            case endpoint_name
            when :new, :edit, :list, :show
              # Find or define the route by resource endpoint name.
              #
              route = controller.routes.values.flatten.find { |possible_route|
                possible_route.name == endpoint_name
              } || controller.send(endpoint_name) do
                operations.reflect(controller: self)
              end
            else
              controller = controller.collection do
                # intentionally empty
              end
            end
          end

          unless route
            # Find or define the route by path.
            #
            route = controller.routes.values.flatten.find { |possible_route|
              possible_route.path == route_path
            } || controller.get(route_name, route_path) do
              operations.reflect(controller: self)
            end
          end

          # Install the reflect action if it hasn't been installed for this route.
          #
          unless @reflected_routes.include?(route)
            if route.name
              endpoint_path = String.normalize_path(
                File.join(controller.path_to_self, String.collapse_path(route.path))
              )

              if route.name == :show
                endpoint_path = File.join(endpoint_path, "show")
              end

              endpoints = @scopes.flat_map(&:endpoints).select { |possible_endpoint|
                possible_endpoint.view_path == endpoint_path
              }

              controller.action :set_reflected_endpoints, only: [route.name] do
                connection.set(:__reflected_endpoints, endpoints)
              end
            else
              # TODO: warn the user that a reflection couldn't be installed for an unnamed route
            end

            @reflected_routes << route
          end
        end

        def find_or_define_controller_for_endpoint(endpoint)
          endpoint_path = if endpoint_directory?(endpoint.view_path)
            endpoint.view_path.split("/")[1..-1]
          else
            endpoint.view_path.split("/")[1..-2]
          end

          if endpoint_path.nil? || endpoint_path.empty?
            controller_for_endpoint_path("", @app) || define_controller_for_endpoint_path("", @app)
          else
            endpoint_path.each_with_index.inject(@app) { |context, (endpoint_path_part, i)|
              controller_for_endpoint_path(endpoint_path_part, context) || define_controller_for_endpoint_path(endpoint_path_part, context, endpoint_path[i + 1])
            }
          end
        end

        def controller_for_endpoint_path(endpoint_path, context)
          endpoint_path = String.normalize_path(endpoint_path)

          state = if context.is_a?(Class) && context.ancestors.include?(Controller)
            context.children
          else
            context.state(:controller)
          end

          state.find { |controller|
            controller.path == endpoint_path
          }
        end

        def define_controller_for_endpoint_path(endpoint_path, context, next_endpoint_path = nil)
          if context.is_a?(Class) && context.ancestors.include?(Controller) && context.expansions.include?(:resource)
            if endpoint_path == "show"
              if needs_resource?(next_endpoint_path)
                context.resource next_endpoint_path.to_sym, String.normalize_path(next_endpoint_path) do
                  # intentionally empty
                end
              else
                context.member do
                  # intentionally empty
                end
              end
            else
              if needs_resource?(endpoint_path)
                if context.__object_name.name == endpoint_path.to_sym
                  context
                else
                  context.collection {}.resource endpoint_path.to_sym, String.normalize_path(endpoint_path) do
                    # intentionally empty
                  end
                end
              else
                collection = context.collection do
                  # intentionally empty
                end

                if endpoint_directory?(File.join(context.path_to_self, endpoint_path))
                  collection.namespace endpoint_path.to_sym, String.normalize_path(endpoint_path) do
                    # intentionally empty
                  end
                else
                  collection
                end
              end
            end
          else
            controller_name = if endpoint_path.empty?
              :root
            else
              endpoint_path.to_sym
            end

            if needs_resource?(controller_name)
              context.resource controller_name, String.normalize_path(endpoint_path) do
                # intentionally empty
              end
            else
              definition_method = if context.is_a?(Class) && context.ancestors.include?(Controller)
                :namespace
              else
                :controller
              end

              context.send(definition_method, controller_name, String.normalize_path(endpoint_path)) do
                # intentionally empty
              end
            end
          end
        end

        def needs_resource?(endpoint_path)
          @app.state(:source).any? { |source| source.plural_name == endpoint_path.to_s.to_sym }
        end

        def endpoint_directory?(endpoint_path)
          @app.state(:templates).any? { |templates|
            File.directory?(File.join(templates.path, templates.config[:paths][:pages], endpoint_path))
          }
        end

        def find_or_define_resource_for_scope(scope)
          context = if scope.parent
            find_or_define_resource_for_scope(scope.parent)
          else
            @app
          end

          resource_for_scope(scope, context) || define_resource_for_scope(scope, context)
        end

        def resource_for_scope(scope, context)
          state = if context.is_a?(Class) && context.ancestors.include?(Controller)
            context.children
          else
            context.state(:controller)
          end

          state.select { |controller|
            controller.ancestors.include?(Routing::Extension::Resource) && controller.__object_name
          }.find { |controller|
            controller.__object_name.name == scope.plural_name
          }
        end

        def define_resource_for_scope(scope, context)
          context.resource scope.plural_name, resource_path_for_scope(scope) do
            # intentionally empty
          end
        end

        def resource_path_for_scope(scope)
          String.normalize_path(scope.plural_name)
        end
      end
    end
  end
end
