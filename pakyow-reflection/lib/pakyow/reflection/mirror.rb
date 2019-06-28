# frozen_string_literal: true

require "pakyow/support/inflector"

require "pakyow/presenter/composers/view"

require "pakyow/reflection/action"
require "pakyow/reflection/attribute"
require "pakyow/reflection/endpoint"
require "pakyow/reflection/nested"
require "pakyow/reflection/scope"

module Pakyow
  module Reflection
    # Reflects state from an application's view templates.
    #
    class Mirror
      using Support::DeepDup

      attr_reader :scopes

      def initialize(app)
        @app, @scopes = app, []
        view_paths.each do |view_path|
          discover_view_scopes(view_path: view_path)
        end
      end

      def scope(name)
        @scopes.find { |scope|
          scope.named?(name)
        }
      end

      private

      def view_paths
        @app.state(:templates).reject { |template_store|
          @app.config.reflection.ignored_template_stores.include?(template_store.name)
        }.flat_map(&:paths)
      end

      def discover_view_scopes(view_path:, view: nil, parent_scope: nil, parent_endpoint: nil)
        unless view
          composer = Presenter::Composers::View.new(view_path, app: @app)
          view = composer.view
        end

        # Descend to find the most specific scope first.
        #
        view.each_binding_scope do |binding_scope_node|
          unless binding_scope_node.significant?(:within_form) || binding_scope_node.labeled?(:plug)
            binding_scope_view = Presenter::View.from_object(binding_scope_node)
            scope = scope_for_binding(binding_scope_view.binding_name, parent_scope)

            # Define an endpoint for this scope.
            #
            endpoint = Endpoint.new(
              view_path,
              scope: scope,
              binding: binding_scope_view.binding_name,
              channel: binding_scope_view.label(:channel),
              parent: parent_endpoint
            )

            scope.endpoints << endpoint

            # Discover nested view scopes.
            #
            discover_view_scopes(
              view_path: view_path,
              view: binding_scope_view,
              parent_scope: scope,
              parent_endpoint: endpoint
            )
          end
        end

        # Discover forms, which build sources.
        #
        view.object.each_significant_node(:form) do |form_node|
          if form_node.labeled?(:binding)
            form_view = Presenter::View.from_object(form_node)
            scope = scope_for_binding(form_view.binding_name, parent_scope)

            # Discover attributes from scopes nested within forms.
            #
            attributes = discover_attributes(form_view)
            attributes.each do |attribute|
              unless scope.attribute(attribute.name)
                scope.attributes << attribute
              end
            end

            # Define an endpoint for this form.
            #
            endpoint = Endpoint.new(
              view_path,
              scope: scope,
              binding: form_view.binding_name,
              channel: form_view.label(:channel),
              parent: parent_endpoint
            )

            scope.endpoints << endpoint

            # Define the reflected action, if there is one.
            #
            if action = action_for_form(form_view, view_path)
              # Define an action to handle this form submission.
              #
              scope.actions << Action.new(
                action,
                # We need the view path to to identify the correct action to pull
                # expected attributes from on submission.
                #
                view_path: view_path,
                # We need the channel to differentiate between submissions of two
                # forms with the same scope from the same view path.
                #
                channel: form_view.label(:channel),
                attributes: attributes,
                nested: discover_nested(form_view)
              )
            end

            # Discover nested form scopes.
            #
            discover_form_scopes(
              view_path: view_path,
              view: form_view,
              parent_scope: scope,
              parent_endpoint: endpoint
            )
          end
        end

        # Define delete actions for delete links.
        #
        view.object.find_significant_nodes(:endpoint).select { |endpoint_node|
          endpoint_node.label(:endpoint).to_s.end_with?("_delete")
        }.each do |endpoint_node|
          scope = scope_for_binding(
            endpoint_node.label(:endpoint).to_s.split("_", 2)[0],
            parent_scope
          )

          unless scope.action(:delete)
            scope.actions << Action.new(:delete, view_path: view_path)
          end
        end
      end

      def discover_form_scopes(view_path:, view: nil, parent_scope: nil, parent_endpoint: nil)
        view.each_binding_scope do |binding_scope_node|
          binding_scope_view = Presenter::View.from_object(binding_scope_node)
          scope = scope_for_binding(binding_scope_view.binding_name, parent_scope)

          # Discover attributes from scopes nested within forms.
          #
          discover_attributes(binding_scope_view).each do |attribute|
            unless scope.attribute(attribute.name)
              scope.attributes << attribute
            end
          end

          # Discover nested form scopes.
          #
          discover_form_scopes(
            view_path: view_path,
            view: binding_scope_view,
            parent_scope: scope
          )
        end
      end

      IGNORED_ATTRIBUTES = %i(id).freeze

      def discover_attributes(view)
        view.binding_props.reject { |binding_prop_node|
          binding_prop_node.significant?(:multipart_binding) && binding_prop_node.label(:binding) != view.binding_name
        }.select { |binding_prop_node|
          Presenter::Form::FIELD_TAGS.include?(binding_prop_node.tagname)
        }.each_with_object([]) do |binding_prop_node, attributes|
          binding_prop_view = Presenter::View.from_object(binding_prop_node)
          binding_prop_name = if binding_prop_node.significant?(:multipart_binding)
            binding_prop_node.label(:binding_prop)
          else
            binding_prop_node.label(:binding)
          end

          unless IGNORED_ATTRIBUTES.include?(binding_prop_name)
            attribute = Attribute.new(
              binding_prop_name,
              type: type_for_form_view(binding_prop_view),
              required: binding_prop_view.attrs.has?(:required)
            )

            attributes << attribute
          end
        end
      end

      def discover_nested(view)
        view.binding_scopes.map { |binding_scope_node|
          binding_scope_view = Presenter::View.from_object(binding_scope_node)

          Nested.new(
            binding_scope_view.binding_name,
            attributes: discover_attributes(binding_scope_view),
            nested: discover_nested(binding_scope_view)
          )
        }
      end

      def scope_for_binding(binding, parent_scope)
        unless scope = scopes.find { |possible_scope| possible_scope.named?(binding) && (possible_scope.parent == parent_scope || possible_scope == parent_scope) }
          scope = Scope.new(binding, parent: parent_scope)
          @scopes << scope
        end

        scope
      end

      def type_for_form_view(view)
        type_for_binding_name(view.binding_name.to_s) || type_for_attribute_type(view.attributes[:type]) || :string
      end

      def type_for_binding_name(binding_name)
        if binding_name.end_with?("_at")
          :datetime
        else
        end
      end

      def type_for_attribute_type(type)
        case type
        when "date"
          :date
        when "time"
          :time
        when "datetime-local"
          :datetime
        when "number", "range"
          :decimal
        else
          nil
        end
      end

      def action_for_form(view, path)
        plural_binding_name = Support.inflector.pluralize(view.binding_name)
        if view.labeled?(:endpoint)
          endpoint = view.label(:endpoint).to_s
          if endpoint.start_with?("#{plural_binding_name}_")
            if endpoint.end_with?("_create")
              :create
            elsif endpoint.end_with?("_update")
              :update
            elsif endpoint.end_with?("_delete")
              :delete
            else
              nil
            end
          else
            nil
          end
        elsif path.include?(plural_binding_name) && (path.include?("show") || path.include?("edit"))
          :update
        else
          :create
        end
      end
    end
  end
end
