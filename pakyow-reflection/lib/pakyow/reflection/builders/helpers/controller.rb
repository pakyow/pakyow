# frozen_string_literal: true

require "pakyow/support/core_refinements/string/normalization"

module Pakyow
  module Reflection
    module Builders
      module Helpers
        module Controller
          using Support::Refinements::String::Normalization

          def find_or_define_controller_at_path(path)
            controller_at_path(path) || define_controller_at_path(path)
          end

          def controller_at_path(path, state = @app.controllers.each.to_a)
            if state.any?
              state.find { |controller|
                String.normalize_path(String.collapse_path(controller.path_to_self)) == String.normalize_path(path)
              } || controller_at_path(path, state.flat_map(&:children))
            else
              nil
            end
          end

          def controller_closest_to_path(path, state = @app.controllers.each.to_a)
            if state.any?
              controller_closest_to_path(path, state.flat_map(&:children)) || state.find { |controller|
                String.normalize_path(path).start_with?(String.normalize_path(String.collapse_path(controller.path_to_self)))
              }
            else
              nil
            end
          end

          def define_controller_at_path(path, within: nil)
            nested_state = if within
              within.children
            else
              @app.controllers.each.to_a
            end

            path = String.normalize_path(path)

            if controller = controller_closest_to_path(path, nested_state)
              context = controller
              path = path.gsub(
                /^#{String.normalize_path(String.collapse_path(controller.path_to_self))}/, ""
              )
            else
              context = within || @app
            end

            controller_name = if path == "/"
              :root
            else
              String.normalize_path(path)[1..-1].gsub("/", "_").to_sym
            end

            method = if context.is_a?(Class) && context.ancestors.include?(Pakyow::Routing::Controller)
              :namespace
            else
              :controller
            end

            context.send(method, controller_name, String.normalize_path(path)) do
              # intentionally empty
            end
          end

          def controller_path(view_path)
            if view_path_directory?(view_path)
              view_path
            else
              view_path.split("/")[0..-2].to_a.join("/")
            end
          end

          def within_resource?(view_path)
            view_path.split("/").any? { |view_path_part|
              @app.sources.each.any? { |source|
                source.plural_name == view_path_part.to_sym
              }
            }
          end

          def route_name(view_path)
            if view_path_directory?(view_path)
              :default
            else
              view_path.split("/").last.to_sym
            end
          end

          def route_path(view_path)
            if view_path_directory?(view_path)
              "/"
            else
              "/#{view_path.split("/").last}"
            end
          end

          def resource_source_at_path(view_path)
            view_path.split("/").reverse.each do |view_path_part|
              @app.sources.each do |source|
                if source.plural_name == view_path_part.to_sym
                  return source
                end
              end
            end
          end

          def view_path_directory?(view_path)
            @app.templates.each.any? { |templates|
              templates.config[:paths][:pages].any? { |pages_path|
                File.directory?(File.join(pages_path, view_path))
              }
            }
          end

          RESOURCE_ENDPOINTS = %i(new edit list show).freeze

          def find_or_define_resource_for_scope_at_path(scope, path, endpoint_type = nil)
            resource = resource_for_scope_at_path(scope, path) || define_resource_for_scope_at_path(scope, path)

            if path.end_with?(resource_path_for_scope(scope)) || endpoint_type.nil? || RESOURCE_ENDPOINTS.include?(path.split("/").last.to_sym)
              return resource
            else
              controller_for_endpoint_type = resource.send(endpoint_type)

              nested_path = if view_path_directory?(path)
                path
              else
                path.split("/")[0..-2].join("/")
              end

              nested_path = nested_path.gsub(
                /^#{String.normalize_path(String.collapse_path(controller_for_endpoint_type.path_to_self))}/, ""
              )

              if current_controller = controller_at_path(nested_path, resource.children)
                return current_controller
              else
                if nested_path.empty?
                  controller_for_endpoint_type
                else
                  define_controller_at_path(nested_path, within: controller_for_endpoint_type)
                end
              end
            end
          end

          def resource_for_scope_at_path(scope, path, state = @app.controllers.each.to_a)
            if state.any?
              state.select { |controller|
                controller.expansions.include?(:resource)
              }.find { |controller|
                String.normalize_path(String.collapse_path(controller.path_to_self)) == full_resource_path_for_scope_at_path(scope, path)
              } || resource_for_scope_at_path(scope, path, state.flat_map(&:children))
            else
              nil
            end
          end

          def define_resource_for_scope_at_path(scope, path)
            context = if resource_namespace_path = resource_namespace_path_for_scope_at_path(scope, path)
              if within_resource?(resource_namespace_path)
                ensure_controller_has_helpers(
                  find_or_define_resource_for_scope_at_path(
                    resource_source_at_path(resource_namespace_path), resource_namespace_path
                  )
                )
              else
                ensure_controller_has_helpers(
                  find_or_define_controller_at_path(resource_namespace_path)
                )
              end
            else
              @app
            end

            context.resource resource_name_for_scope(scope), resource_path_for_scope(scope) do
              # intentionally empty
            end
          end

          def resource_namespace_path_for_scope_at_path(scope, path)
            resource_path = resource_path_for_scope(scope)

            if path.start_with?(resource_path)
              nil
            elsif path.include?(resource_path)
              path.split(resource_path, 2)[0]
            end
          end

          def resource_name_for_scope(scope)
            scope.plural_name
          end

          def resource_path_for_scope(scope)
            String.normalize_path(scope.plural_name)
          end

          def ensure_controller_has_helpers(controller)
            unless controller.ancestors.include?(Extension::Controller)
              controller.include Extension::Controller
            end

            controller
          end

          def find_or_define_resource_for_scope_in_resource(scope, resource)
            resource.children.find { |child|
              child.path == resource_path_for_scope(scope)
            } || resource.resource(resource_name_for_scope(scope), resource_path_for_scope(scope)) do
              # intentionally empty
            end
          end

          def full_resource_path_for_scope_at_path(scope, path)
            String.normalize_path(
              File.join(
                resource_namespace_path_for_scope_at_path(scope, path).to_s,
                scope.plural_name.to_s
              )
            )
          end
        end
      end
    end
  end
end
