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
    # @api private
    class Mirror
      using Support::DeepDup

      attr_reader :scopes, :endpoints, :actions

      def initialize(app)
        @app, @scopes, @endpoints, @actions = app, [], [], []

        view_paths.each do |view_path|
          discover_view_scopes(view_path: view_path)
        end

        view_paths.each do |view_path|
          discover_view_path_associations(view_path: view_path)
        end
      end

      def scope(name)
        @scopes.find { |scope|
          scope.named?(name)
        }
      end

      private

      def view_paths
        @app.templates.each.reject { |template_store|
          @app.config.reflection.ignored_template_stores.include?(template_store.name)
        }.flat_map(&:paths)
      end

      def discover_view_scopes(view_path:, view: nil, parent_scope: nil, parent_exposure: nil, binding_path: [])
        unless view
          composer = Presenter::Composers::View.new(view_path, app: @app)
          view = composer.view(return_cached: true)
        end

        # Descend to find the most specific scope first.
        #
        view.each_binding_scope.reject { |binding_scope_node|
          binding_scope_node.significant?(:within_form) || binding_scope_node.labeled?(:plug)
        }.group_by { |binding_scope_node|
          binding_scope_node.label(:channeled_binding)
        }.each do |channeled_binding_name, binding_scope_nodes|
          scope = scope_for_binding(binding_scope_nodes[0].label(:binding), parent_scope)

          # Discover attributes from scopes nested within views.
          #
          binding_scope_nodes.each do |binding_scope_node|
            discover_attributes(Presenter::View.from_object(binding_scope_node), fields: false).each do |attribute|
              unless scope.attribute(attribute.name, type: :view)
                scope.add_attribute(attribute, type: :view)
              end
            end
          end

          # Define an endpoint for this scope.
          #
          endpoint = ensure_endpoint(
            view_path, view.info.dig(:reflection, :endpoint)
          )

          exposure = endpoint.exposures.find { |e|
            e.binding == channeled_binding_name && e.parent.equal?(parent_exposure)
          }

          unless exposure
            exposure = Exposure.new(
              scope: scope,
              nodes: binding_scope_nodes,
              parent: parent_exposure,
              binding: channeled_binding_name,
              dataset: binding_scope_nodes[0].label(:dataset)
            )

            endpoint.add_exposure(exposure)
          end

          # Discover nested view scopes.
          #
          binding_scope_nodes.each do |binding_scope_node|
            discover_view_scopes(
              view_path: view_path,
              view: Presenter::View.from_object(binding_scope_node),
              parent_scope: scope,
              parent_exposure: exposure,
              binding_path: binding_path.dup << binding_scope_node.label(:binding)
            )
          end
        end

        # Discover forms.
        #
        view.object.each_significant_node(:form).select { |form_node|
          form_node.labeled?(:binding) && !form_node.labeled?(:plug)
        }.each do |form_node|
          form_view = Presenter::View.from_object(form_node)
          scope = scope_for_binding(form_view.binding_name, parent_scope)

          # Discover attributes from scopes nested within forms.
          #
          attributes = discover_attributes(form_view)
          attributes.each do |attribute|
            unless scope.attribute(attribute.name, type: :form)
              scope.add_attribute(attribute, type: :form)
            end
          end

          # Define an endpoint for this form.
          #
          endpoint = ensure_endpoint(
            view_path, view.info.dig(:reflection, :endpoint)
          )

          unless endpoint.exposures.any? { |e| e.binding == form_view.channeled_binding_name }
            exposure = Exposure.new(
              scope: scope,
              nodes: [form_node],
              parent: parent_exposure,
              binding: form_view.channeled_binding_name
            )

            endpoint.add_exposure(exposure)

            # Define the reflected action, if there is one.
            #
            if action = action_for_form(form_view, view_path)
              # Define an action to handle this form submission.
              #
              scope.actions << Action.new(
                name: action,
                scope: scope,
                node: form_node,

                # We need the view path to to identify the correct action to pull
                # expected attributes from on submission.
                #
                view_path: view_path,

                # We need the channeled binding name to differentiate between submissions of two
                # forms with the same scope from the same view path.
                #
                binding: form_view.label(:channeled_binding),

                attributes: attributes,
                nested: discover_nested(form_view),
                parents: binding_path.map { |binding_path_part|
                  scope(binding_path_part)
                }
              )
            end

            # Discover nested form scopes.
            discover_form_scopes(
              view_path: view_path,
              view: form_view,
              parent_scope: scope,
              parent_exposure: exposure
            )
          end
        end

        # Define delete actions for delete links.
        #
        view.object.find_significant_nodes(:endpoint).select { |endpoint_node|
          endpoint_node.label(:endpoint).to_s.end_with?("_delete")
        }.reject { |endpoint_node|
          endpoint_node.label(:endpoint).to_s.start_with?("@")
        }.each do |endpoint_node|
          scope = scope_for_binding(
            endpoint_node.label(:endpoint).to_s.split("_", 2)[0],
            parent_scope
          )

          if scope && endpoint_node.label(:endpoint).to_s == "#{scope.plural_name}_delete" && !scope.action(:delete)
            scope.actions << Action.new(
              name: :delete,
              scope: scope,
              node: endpoint_node,
              view_path: view_path
            )
          end
        end
      end

      def discover_view_path_associations(view_path:)
        view_path_parts = view_path.split("/").reverse.map(&:to_sym)

        until view_path_parts.count < 2
          view_path_part = view_path_parts.shift

          if child_scope = scope(view_path_part)
            view_path_parts.map { |each_view_path_part|
              scope(each_view_path_part)
            }.compact.each do |parent_scope|
              child_scope.add_parent(parent_scope)
            end
          end
        end
      end

      def discover_form_scopes(view_path:, view: nil, parent_scope: nil, parent_exposure: nil)
        view.each_binding_scope do |binding_scope_node|
          if binding_scope_node.significant?(:field) || binding_scope_node.find_significant_nodes(:field).any?
            binding_scope_view = Presenter::View.from_object(binding_scope_node)
            scope = scope_for_binding(binding_scope_view.binding_name, parent_scope)

            # Discover attributes from scopes nested within forms.
            #
            discover_attributes(binding_scope_view).each do |attribute|
              unless scope.attribute(attribute.name, type: :form)
                scope.add_attribute(attribute, type: :form)
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
      end

      IGNORED_ATTRIBUTES = %i(id).freeze

      def discover_attributes(view, fields: true)
        view.binding_props.reject { |binding_prop_node|
          binding_prop_node.significant?(:multipart_binding) && binding_prop_node.label(:binding) != view.binding_name
        }.select { |binding_prop_node|
          !fields || Presenter::Views::Form::FIELD_TAGS.include?(binding_prop_node.tagname)
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
        view.binding_scopes.select { |binding_scope_node|
          binding_scope_node.significant?(:field) || binding_scope_node.find_significant_nodes(:field).any?
        }.map { |binding_scope_node|
          binding_scope_view = Presenter::View.from_object(binding_scope_node)

          Nested.new(
            binding_scope_view.binding_name,
            attributes: discover_attributes(binding_scope_view),
            nested: discover_nested(binding_scope_view)
          )
        }
      end

      def scope_for_binding(binding, parent_scope)
        unless scope = scopes.find { |possible_scope| possible_scope.named?(binding) }
          scope = Scope.new(binding); @scopes << scope
        end

        if parent_scope
          scope.add_parent(parent_scope)
        end

        scope
      end

      def type_for_form_view(view)
        type_for_binding_name(view.binding_name.to_s) ||
        (view.attributes.has?(:type) && type_for_attribute_type(view.attributes[:type])) ||
        :string
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
          if endpoint.end_with?("#{plural_binding_name}_create")
            :create
          elsif endpoint.end_with?("#{plural_binding_name}_update")
            :update
          elsif endpoint.end_with?("#{plural_binding_name}_delete")
            :delete
          else
            nil
          end
        elsif path.include?(plural_binding_name) && path.include?("edit")
          :update
        else
          :create
        end
      end

      def ensure_endpoint(view_path, options)
        unless endpoint = @endpoints.find { |e| e.view_path == view_path }
          endpoint = Endpoint.new(view_path, options: options)
          @endpoints << endpoint
        end

        endpoint
      end
    end
  end
end
