# frozen_string_literal: true

require "securerandom"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/inflector"

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    # Presents a form.
    #
    class FormPresenter < Presenter
      using Support::Refinements::Array::Ensurable

      SUPPORTED_ACTIONS = %i(create update replace delete).freeze
      ACTION_METHODS = { create: "post", update: "patch", replace: "put", delete: "delete" }.freeze

      # @api private
      ID_LABEL = :__form_id

      def id
        @view.label(ID_LABEL)
      end

      # Sets the form action (where it submits to).
      #
      def action=(action)
        if action.is_a?(Symbol)
          @view.object.set_label(:endpoint, action)
          setup_form_endpoint(build_endpoints(nodes: [@view.object]).first)
        else
          @view.attrs[:action] = action
        end
      end

      # Sets the form method. Automatically handles method overrides by prepending a hidden field
      # named `_method` when +method+ is not get or post, setting the form method to +post+.
      #
      def method=(method)
        method = method.to_s.downcase
        if method_override_required?(method)
          @view.attrs[:method] = "post"

          find_or_create_method_override_input.attributes[:value] = method
        else
          @view.attrs[:method] = method
        end
      end

      # Populates a select field with options.
      #
      def options_for(field, options = nil)
        unless field_view = @view.find(field) || @view.find(Support.inflector.singularize(field)) || @view.find(Support.inflector.pluralize(field))
          raise ArgumentError.new("could not find field named `#{field}'")
        end

        unless options_for_allowed?(field_view)
          raise ArgumentError.new("expected `#{field}' to be a select field, checkbox, or radio button")
        end

        options = if block_given?
          yield(field_view)
        else
          options
        end

        case field_view.object.tagname
        when "select"
          create_select_options(options, field_view)
        when "input"
          create_input_options(options, field_view)
        else
          create_options(options, field_view)
        end
      end

      # Populates a select field with grouped options.
      #
      def grouped_options_for(field, options = nil)
        unless field_view = @view.find(field)
          raise ArgumentError.new("could not find field named `#{field}'")
        end

        unless grouped_options_for_allowed?(field_view)
          raise ArgumentError.new("expected `#{field}' to be a select field")
        end

        options = options || yield
        case field_view.object.tagname
        when "select"
          create_grouped_select_options(options, field_view)
        end
      end

      def setup(object = {})
        if @view.labeled?(:endpoint)
          setup_form_endpoint(build_endpoints(object, nodes: [@view.object]).first)
        end

        setup_field_names
        connect_labels
        use_binding_nodes

        yield self if block_given?
        @view.bind(object)
        @view.object.set_label(:__form_setup, true)
        self
      end

      # Setup the form for creating an object.
      #
      def create(object = {})
        yield self if block_given?
        setup_form_for_binding(:create, object)
      end

      # Setup the form for updating an object.
      #
      def update(object)
        yield self if block_given?
        setup_form_for_binding(:update, object)
      end

      # Setup the form for replacing an object.
      #
      def replace(object)
        yield self if block_given?
        setup_form_for_binding(:replace, object)
      end

      # Setup the form for removing an object.
      #
      def delete(object)
        yield self if block_given?
        setup_form_for_binding(:delete, object)
      end

      # @ api private
      def embed_authenticity_token(token, param:)
        @view.prepend(authenticity_token_input(token, param: param))
      end

      # @ api private
      def embed_metadata(metadata)
        @view.prepend(metadata_input(metadata))
      end

      private

      def setup_form_for_binding(action, object)
        setup(object) do
          if SUPPORTED_ACTIONS.include?(action)
            unless @view.labeled?(:endpoint)
              if self.action = form_action_for_binding(action, object)
                self.method = method_for_action(action)
              end
            end
          else
            raise ArgumentError.new("expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}")
          end
        end
      end

      def setup_field_names(view = @view)
        view.object.children.each_significant_node_without_descending(:binding) do |binding_node|
          if Form::FIELD_TAGS.include?(binding_node.tagname)
            if binding_node.attributes[:name].to_s.empty?
              binding_node.attributes[:name] = "#{view.object.label(:binding)}[#{binding_node.label(:binding)}]"
            end

            if binding_node.tagname == "select" && binding_node.attributes[:multiple]
              pluralize_field_name(binding_node)
            end
          end
        end
      end

      def connect_labels(view = @view)
        view.object.children.each_significant_node_without_descending(:label) do |label_node|
          if label_node.attributes[:for] && input = view.find(*label_node.attributes[:for].to_s.split("."))
            connect_input_to_label(input, label_node)
          end
        end
      end

      def connect_input_to_label(input, label)
        if false || input.attributes[:id].to_s.empty?
          id = SecureRandom.hex(4)
          input.attributes[:id] = id
        else
          id = input.attributes[:id]
        end

        label.attributes[:for] = id
      end

      def use_binding_nodes
        @view.object.set_label(:used, true)
        @view.object.children.each_significant_node(:binding) do |object|
          object.set_label(:used, true)
        end
      end

      def form_action_for_binding(action, object)
        [
          Support.inflector.singularize(@view.label(:binding)).to_sym,
          Support.inflector.pluralize(@view.label(:binding)).to_sym
        ].map { |possible_endpoint_name|
          @app.endpoints.path_to(possible_endpoint_name, action, **object.to_h)
        }.compact.first
      end

      def method_for_action(action)
        ACTION_METHODS[action]
      end

      def method_override_required?(method)
        method != "get" && method != "post"
      end

      def method_override_input
        safe("<input type=\"hidden\" name=\"_method\">")
      end

      def find_or_create_method_override_input
        unless input = @view.object.find_first_significant_node_without_descending(:method_override)
          @view.prepend(method_override_input)
          input = @view.object.find_first_significant_node_without_descending(:method_override)
        end

        input
      end

      def authenticity_token_input(token, param:)
        safe("<input type=\"hidden\" name=\"#{param}\" value=\"#{token}\">")
      end

      def metadata_input(metadata)
        safe("<input type=\"hidden\" name=\"_form\" value=\"#{metadata}\">")
      end

      def create_select_options(values, field_view)
        options = Oga::XML::Document.new

        Array.ensure(values).compact.each do |value|
          options.children << create_select_option(value, field_view)
        end

        add_options_to_select(options, field_view)
      end

      def create_grouped_select_options(values, field_view)
        options = Oga::XML::Document.new

        values.each do |group_name, grouped_values|
          group = Oga::XML::Element.new(name: "optgroup")
          group.set("label", ensure_html_safety(group_name.to_s))
          options.children << group

          grouped_values.each do |value|
            group.children << create_select_option(value, field_view)
          end
        end

        add_options_to_select(options, field_view)
      end

      def create_select_option(value, view)
        option_binding = if option = view.object.find_first_significant_node(:option)
          option.label(:binding)
        else
          nil
        end

        Oga::XML::Element.new(name: "option").tap do |option_node|
          option_node.set("value", ensure_html_safety(option_value(value, view).to_s))

          display_value = if value.is_a?(Array)
            value[1]
          elsif option_binding && value.respond_to?(:[])
            value[option_binding.to_sym]
          else
            nil
          end

          option_node.inner_text = ensure_html_safety(display_value.to_s)
        end
      end

      def create_input_options(values, field_view)
        if values.is_a?(Array) && field_view.attributes[:type] != "radio"
          pluralize_field_name(field_view.object)
        end

        values = Array.ensure(values).compact

        if values.any?
          field_template = field_view.dup
          insertable_field = field_view
          current_field = Form.from_object(field_view.object)

          values.each do |value|
            current_field.attributes[:value] = option_value(value, field_view).to_s

            unless current_field.object.equal?(field_view.object)
              insertable_field.after(current_field)
              insertable_field = current_field
            end

            current_field = field_template.dup
          end
        else
          field_view.remove
        end
      end

      def create_options(original_values, field_view)
        values = Array.ensure(original_values).compact

        if values.any?
          template = field_view.dup
          insertable = field_view
          current = Form.from_object(field_view.object)

          values.each do |value|
            if treat_as_nested?(current, value)
              current.bind(value)

              # Set the field names appropriately.
              #
              current.object.each_significant_node_without_descending(:field) do |field|
                name = "#{@view.object.label(:binding)}[#{current.label(:binding)}]"
                name = if original_values.is_a?(Array)
                  "#{name}[][#{field.label(:binding)}]"
                else
                  "#{name}[#{field.label(:binding)}]"
                end

                field.attributes[:name] = name
              end

              # Insert a hidden field to identify the data on submission.
              #
              if key = option_value_keys(current, value).find { |k| value.include?(k) }
                id_input = Oga::XML::Element.new(name: "input")
                id_input.set(:type, "hidden")
                name = "#{@view.object.label(:binding)}[#{current.label(:binding)}]"
                name = if original_values.is_a?(Array)
                  "#{name}[][#{key}]"
                else
                  "#{name}[#{key}]"
                end
                id_input.set(:name, name)
                id_input.set(:value, ensure_html_safety(value[key].to_s))
                current.prepend(safe(id_input.to_xml))
              end
            else
              if input = current.object.find_first_significant_node(:field)
                input.attributes[:name] = "#{@view.object.label(:binding)}[#{current.label(:binding)}]"

                if original_values.is_a?(Array) && input.attributes[:type] != "radio"
                  pluralize_field_name(input)
                end

                input.attributes[:value] = ensure_html_safety(option_value(value, current).to_s)
              end

              if label = current.object.find_first_significant_node(:label)
                label.html = ensure_html_safety(label_value(value, label).to_s)
              end

              if input && label
                connect_input_to_label(input, label)
              end
            end

            unless current.object.equal?(field_view.object)
              insertable.after(current)
              insertable = current
            end

            current = template.dup
          end
        else
          field_view.remove
        end
      end

      def treat_as_nested?(view, value)
        if value.is_a?(Array)
          false
        else
          keys = option_value_keys(view, value, false)
          view.object.each_significant_node(:field) do |field|
            return true if field.labeled?(:binding) && !keys.include?(field.label(:binding))
          end

          false
        end
      end

      def option_value(value, view)
        if value.is_a?(Array)
          value[0]
        elsif value.is_a?(String)
          value
        elsif value.respond_to?(:[])
          option_value_keys(view, value).each do |key|
            if value.include?(key)
              return value[key]
            end
          end

          nil
        else
          value.to_s
        end
      end

      def label_value(value, view)
        if value.is_a?(Array)
          value[1]
        elsif value.is_a?(String)
          value
        elsif view.labeled?(:binding) && value.respond_to?(:[])
          value[view.label(:binding)]
        else
          nil
        end
      end

      def option_value_keys(view, value, include_binding_prop = true)
        [].tap do |keys|
          if include_binding_prop
            keys << view.object.label(:binding_prop)
          end

          if value.class.respond_to?(:primary_key_field)
            keys << value.class.primary_key_field
          end

          keys << :id
        end.compact
      end

      def options_for_allowed?(field_view)
        field_view.object.tagname == "select" || (
          field_view.object.tagname == "input" && (
            field_view.object.attributes[:type] == "checkbox" || field_view.object.attributes[:type] == "radio"
          ) ||
          field_view.object.significant?(:binding)
        )
      end

      def grouped_options_for_allowed?(field_view)
        field_view.object.tagname == "select"
      end

      def add_options_to_select(options, field_view)
        # remove existing options
        field_view.clear

        # add generated options
        field_view.append(safe(options.to_xml))
      end

      def setup_form_endpoint(endpoint)
        self.action = endpoint[:path]
        self.method = endpoint[:method]
      end

      def pluralize_field_name(field)
        unless field.attributes[:name].to_s.end_with?("[]") || field.attributes[:name].to_s.empty?
          field.attributes[:name] = "#{field.attributes[:name]}[]"
        end
      end
    end
  end
end
