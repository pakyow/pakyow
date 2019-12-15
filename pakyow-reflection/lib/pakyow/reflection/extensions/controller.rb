# frozen_string_literal: true

require "pakyow/support/core_refinements/array/ensurable"

require "pakyow/support/extension"

module Pakyow
  module Reflection
    module Extension
      module Controller
        extend Support::Extension
        restrict_extension Controller
        using Support::Refinements::Array::Ensurable

        def with_reflected_action
          if reflected_action
            yield reflected_action
          else
            trigger 404
          end
        end

        def with_reflected_endpoint
          if reflected_endpoint
            yield reflected_endpoint
          else
            trigger 404
          end
        end

        def reflective_expose
          reflected_endpoint.exposures.each do |reflected_exposure|
            if reflected_exposure.parent.nil? || reflected_exposure.binding.to_s.include?("form")
              if dataset = reflected_exposure.dataset
                query = data.send(reflected_exposure.scope.plural_name)

                if dataset.include?(:limit)
                  query = query.limit(dataset[:limit].to_i)
                end

                if dataset.include?(:order)
                  query = query.order(*dataset[:order].to_a)
                end

                if dataset.include?(:query) && dataset[:query] != "all"
                  case dataset[:query]
                  when Array
                    dataset[:query].each do |key, value|
                      value = if respond_to?(value)
                        public_send(value)
                      else
                        value
                      end

                      query = query.public_send(key, value)
                    end
                  else
                    query = query.public_send(dataset[:query].to_s)
                  end
                end
              else
                query = data.send(reflected_exposure.scope.plural_name)

                if reflects_specific_object?(reflected_exposure.scope.plural_name)
                  if resource = resource_with_name(reflected_exposure.scope.plural_name)
                    if resource == self.class
                      query_param = resource.param
                      params_param = resource.param
                    else
                      query_param = resource.param
                      params_param = resource.nested_param
                    end

                    query = query.send(:"by_#{query_param}", params[params_param])
                  end
                end
              end

              query = apply_includes_to_query(query, reflected_exposure.scope.plural_name, reflected_exposure.children)

              if reflects_specific_object?(reflected_exposure.scope.plural_name) && query.count == 0
                trigger 404
              else
                if !reflected_exposure.binding.to_s.include?("form") || reflected_endpoint.view_path.end_with?("/edit")
                  logger.debug {
                    "[reflection] exposing dataset for `#{reflected_exposure.binding}': #{query.inspect}"
                  }

                  expose reflected_exposure.binding.to_s, query
                end
              end
            end
          end
        end

        def verify_reflected_form
          with_reflected_action do |reflected_action|
            local = self

            verify do
              required reflected_action.scope.name do
                reflected_action.attributes.each do |attribute|
                  if attribute.required?
                    required attribute.name do
                      validate :presence
                    end
                  else
                    optional attribute.name
                  end
                end

                local.__send__(:verify_nested_data, reflected_action.nested, self)
              end
            end

            logger.debug {
              "[reflection] verified and validated submitted values for `#{reflected_action.scope.name}'"
            }
          end
        end

        def perform_reflected_action
          with_reflected_action do |reflected_action|
            logger.debug {
              "[reflection] performing `#{[self.class.name_of_self, connection.values[:__endpoint_name]].join("_")}' for `#{reflected_action.view_path}'"
            }

            proxy = data.public_send(reflected_action.scope.plural_name)

            # Pull initial values from the params.
            #
            values = params[reflected_action.scope.name]

            # Associate the object with its parent when creating.
            #
            if self.class.parent && connection.get(:__endpoint_name) == :create
              # TODO: Handle cases where objects are associated by id but routed by another field.
              # Implement when we allow foreign keys to be specified in associations.
              #
              if proxy.source.class.attributes.key?(self.class.parent.nested_param)
                values[self.class.parent.nested_param] = params[self.class.parent.nested_param]
              end
            end

            # Limit the action for update, delete.
            #
            if connection.get(:__endpoint_name) == :update || connection.get(:__endpoint_name) == :delete
              proxy = proxy.public_send(:"by_#{proxy.source.class.primary_key_field}", params[self.class.param])
              trigger 404 if proxy.count == 0
            end

            proxy.transaction do
              unless connection.get(:__endpoint_name) == :delete
                handle_nested_values_for_source(values, proxy.source.class)
              end

              @object = proxy.send(
                connection.get(:__endpoint_name), values
              )
            end

            logger.debug {
              "[reflection] changes have been saved to the `#{proxy.source.class.plural_name}' data source"
            }
          end
        rescue Data::ConstraintViolation
          trigger 404
        end

        def redirect_to_reflected_destination
          if destination = reflected_destination
            logger.debug {
              "[reflection] redirecting to `#{destination}'"
            }

            redirect destination
          end
        end

        def reflected_destination
          with_reflected_action do |reflected_action|
            if connection.form && origin = connection.form[:origin]
              if instance_variable_defined?(:@object)
                if route = self.class.routes[:get].find { |route| route.name == :show }
                  route.build_path(self.class.path_to_self, **params.merge(@object.one.to_h))
                elsif route = self.class.routes[:get].find { |route| route.name == :list }
                  route.build_path(self.class.path_to_self, **params)
                else
                  origin
                end
              else
                origin
              end
            else
              nil
            end
          end
        end

        private

        def reflected_action
          connection.get(:__reflected_action)
        end

        def reflected_endpoint
          connection.get(:__reflected_endpoint)
        end

        def reflects_specific_object?(object_name)
          (
            self.class.object_name.name == object_name && (
              connection.get(:__endpoint_name) == :show || connection.get(:__endpoint_name) == :edit
            )
          ) || parent_resource_named?(object_name)
        end

        def parent_resource_named?(object_name, context = self.class)
          if context && context.parent
            context.parent.object_name&.name == object_name || parent_resource_named?(object_name, context.parent)
          else
            false
          end
        end

        def resource_with_name(object_name, context = self.class)
          if context.object_name&.name == object_name
            context
          elsif context.parent
            resource_with_name(object_name, context.parent)
          end
        end

        def verify_nested_data(nested, context)
          local = self
          nested.each do |object|
            context.required object.name do
              optional local.data.public_send(object.plural_name).source.class.primary_key_field

              object.attributes.each do |attribute|
                if attribute.required?
                  required attribute.name
                else
                  optional attribute.name
                end
              end

              local.__send__(:verify_nested_data, object.nested, self)
            end
          end
        end

        def handle_nested_values_for_source(values, source)
          source.associations.values_at(:has_one, :has_many).flatten.each do |association|
            Array.ensure(values).each do |object|
              if object.include?(association.name)
                handle_nested_values_for_source(
                  object[association.name],
                  association.associated_source
                )

                if association.result_type == :many
                  object[association.name] = Array.ensure(object[association.name]).map { |related|
                    if related.include?(association.associated_source.primary_key_field)
                      data.public_send(association.associated_source_name).send(
                        :"by_#{association.associated_source.primary_key_field}",
                        related[association.associated_source.primary_key_field]
                      ).update(related).one
                    else
                      data.public_send(association.associated_source_name).create(related).one
                    end
                  }
                else
                  related = object[association.name]
                  object[association.name] = if related.include?(association.associated_source.primary_key_field)
                    data.public_send(association.associated_source_name).send(
                      :"by_#{association.associated_source.primary_key_field}",
                      related[association.associated_source.primary_key_field]
                    ).update(related).one
                  else
                    data.public_send(association.associated_source_name).create(related).one
                  end
                end
              end
            end
          end
        end

        def apply_includes_to_query(query, plural_name, children)
          associations = data.send(
            plural_name
          ).source.class.associations.values.flatten

          children.group_by { |child|
            child.scope.plural_name
          }.each do |nested_plural_name, child_exposures|
            association = associations.find { |possible_association|
              possible_association.associated_source_name == nested_plural_name
            }

            if association
              context = self
              query = query.including(association.name) {
                context.__send__(:apply_includes_to_query, self, nested_plural_name, child_exposures.flat_map(&:children))
              }
            end
          end

          query
        end
      end
    end
  end
end
