# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

require "pakyow/reflection/builders/base"
require "pakyow/reflection/builders/helpers/controller"
require "pakyow/reflection/extensions/controller"

module Pakyow
  module Reflection
    module Builders
      # @api private
      class Endpoints < Base
        include Helpers::Controller

        using Support::Refinements::String::Normalization

        def build(endpoints)
          endpoints.each do |endpoint|
            define_endpoint(endpoint)
          end
        end

        private

        def define_endpoint(endpoint)
          controller = if within_resource?(endpoint.view_path)
            find_or_define_resource_for_scope_at_path(
              resource_source_at_path(endpoint.view_path),
              controller_path(endpoint.view_path),
              endpoint.type
            )
          else
            find_or_define_controller_at_path(controller_path(endpoint.view_path))
          end

          # TODO: Make this the responsibility of the helpers.
          #
          ensure_controller_has_helpers(controller)

          if controller.expansions.include?(:resource)
            endpoint_name = String.normalize_path(
              endpoint.view_path.gsub(String.collapse_path(controller.path_to_self), "")
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
                reflect
              end
            end
          end

          route ||= controller.routes.values.flatten.find { |possible_route|
            possible_route.path == route_path(endpoint.view_path)
          } || controller.get(route_name(endpoint.view_path), route_path(endpoint.view_path)) do
                 operations.reflect(controller: self)
               end

          if route.name
            controller.action :set_reflected_endpoint, only: [route.name] do
              connection.set(:__reflected_endpoint, endpoint)
            end
            # else
            # TODO: warn the user that a reflection couldn't be installed for an unnamed route
          end
        end
      end
    end
  end
end
