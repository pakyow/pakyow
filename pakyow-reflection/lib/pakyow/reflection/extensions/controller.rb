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

        apply_extension do
        end

        private

        # @api public
        def reflective_expose
          # TODO: implement
        end

        # @api public
        def reflective_create
          verify_submitted_form
          handle_submitted_data
          redirect_from_action
        end

        # @api public
        def reflective_update
          verify_submitted_form
          handle_submitted_data
          redirect_from_action
        end

        # @api public
        def reflective_delete
          handle_submitted_data
          redirect_from_action
        end

        # @api public
        def verify_submitted_form
          with_reflected_scope do |reflected_scope|
            with_reflected_action do |reflected_action|
              local = self

              verify do
                required reflected_scope.name do
                  reflected_action.attributes.each do |attribute|
                    if attribute.required?
                      required attribute.name
                    else
                      optional attribute.name
                    end
                  end

                  local.__send__(:verify_nested_data, reflected_action.nested, self)
                end
              end
            end
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

        # @api public
        def handle_submitted_data
          with_reflected_scope do |reflected_scope|
            proxy = data.public_send(reflected_scope.plural_name)

            # Pull initial values from the params.
            #
            values = params[reflected_scope.name]

            # Associate the object with its parent when creating.
            #
            if self.class.parent && connection.env["pakyow.endpoint.name"] == :create
              values[self.class.parent.nested_param] = params[self.class.parent.nested_param]
            end

            # Limit the action for update, delete.
            #
            if connection.env["pakyow.endpoint.name"] == :update || connection.env["pakyow.endpoint.name"] == :delete
              proxy = proxy.public_send(:"by_#{proxy.source.class.primary_key_field}", params[self.class.param])
              trigger 404 if proxy.count == 0
            end

            proxy.transaction do
              handle_nested_values_for_source(values, proxy.source.class)

              @object = proxy.send(
                connection.env["pakyow.endpoint.name"], values
              )
            end
          end
        rescue Data::ConstraintViolation => e
          trigger 404
        rescue => e
          # TODO: remove this
          pp e
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

        # @api public
        def redirect_from_action
          if destination = action_destination
            redirect destination
          end
        end

        # @api public
        def action_destination
          with_reflected_scope do |reflected_scope|
            if connection.form && origin = connection.form[:origin]
              if instance_variable_defined?(:@object) && origin == "/#{reflected_scope.plural_name}/new"
                if self.class.routes[:get].any? { |route| route.name == :show }
                  path(:"#{reflected_scope.plural_name}_show", @object.one.to_h)
                elsif self.class.routes[:get].any? { |route| route.name == :list }
                  path(:"#{reflected_scope.plural_name}_list")
                end
              else
                origin
              end
            else
              nil
            end
          end
        end

        def with_reflected_scope
          if reflected_scope
            yield reflected_scope
          else
            trigger 404
          end
        end

        def reflected_scope
          connection.get(:__reflected_scope)
        end

        def with_reflected_action
          if reflected_action
            yield reflected_action
          else
            trigger 404
          end
        end

        def reflected_action
          connection.get(:__reflected_action)
        end
      end
    end
  end
end
