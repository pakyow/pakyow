# frozen_string_literal: true

require "securerandom"

require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    # Presents a form.
    #
    class FormPresenter < Presenter
      SUPPORTED_ACTIONS = %i(create update replace delete).freeze
      ACTION_METHODS = { create: "post", update: "patch", replace: "put", delete: "delete" }.freeze

      # @api private
      ID_LABEL = :__form_id

      def initialize(*)
        super

        unless @view.labeled?(ID_LABEL)
          setup_form_id
        end

        setup_form_binding
        setup_field_names
        use_binding_nodes
      end

      def id
        @view.label(ID_LABEL)
      end

      # Sets the form action (where it submits to).
      #
      def action=(action)
        if action.is_a?(Symbol)
          @view.object.set_label(:endpoint, action)
          setup_form_endpoint(build_endpoints([@view.object]).first)
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
        unless field_view = @view.find(field)
          raise ArgumentError.new("could not find field named `#{field}'")
        end

        unless options_for_allowed?(field_view)
          raise ArgumentError.new("expected `#{field}' to be a select field")
        end

        options = options || yield
        case field_view.object.tagname
        when "select"
          create_select_options(options, field_view)
        when "input"
          create_input_options(options, field_view)
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

      def setup(object)
        endpoint = build_endpoints([@view.object], object).first
        setup_form_endpoint(endpoint)
      end

      # Setup the form for creating an object.
      #
      def create(object = {})
        yield self if block_given?
        setup_form_for_binding :create, object
      end

      # Setup the form for updating an object.
      #
      def update(object)
        yield self if block_given?
        setup_form_for_binding :update, object
      end

      # Setup the form for replacing an object.
      #
      def replace(object)
        yield self if block_given?
        setup_form_for_binding :replace, object
      end

      # Setup the form for removing an object.
      #
      def delete(object)
        yield self if block_given?
        setup_form_for_binding :delete, object
      end

      # @ api private
      def embed_authenticity_token(token, param:)
        @view.prepend(authenticity_token_input(token, param: param))
      end

      # @ api private
      def embed_origin(origin)
        @view.prepend(origin_input(origin))
      end

      protected

      def setup_form_for_binding(action, object)
        action = action.to_sym
        if SUPPORTED_ACTIONS.include?(action)
          if self.action = form_action_for_binding(action, object)
            self.method = method_for_action(action)
          end

          @view.bind(object)
        else
          raise ArgumentError.new("expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}")
        end
      end

      def setup_form_id
        id = SecureRandom.hex(24)
        @view.object.set_label(ID_LABEL, id)
        embed_id(id)
      end

      def setup_form_binding
        @view.prepend(binding_input)
      end

      def setup_field_names
        @view.object.children.find_significant_nodes_without_descending(:binding).reject { |binding_node|
          binding_node.significant?(:multipart_binding)
        }.each do |binding_node|
          binding_node.attributes[:name] ||= "#{@view.object.label(:binding)}[#{binding_node.label(:binding)}]"
        end
      end

      def use_binding_nodes
        [@view.object].concat(@view.object.children.find_significant_nodes(:binding)).each do |object|
          object.set_label(:used, true)
        end
      end

      def embed_id(id)
        @view.prepend(id_input(id))
      end

      def form_action_for_binding(action, object)
        if endpoint_state_defined?
          [
            Support.inflector.singularize(@view.label(:binding)).to_sym,
            Support.inflector.pluralize(@view.label(:binding)).to_sym
          ].map { |possible_endpoint_name|
            @endpoints.path_to(possible_endpoint_name, action, **form_action_params(object))
          }.compact.first
        end
      end

      def form_action_params(object)
        {}.tap do |params|
          params[:id] = object[:id] if object
        end
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
        unless input = @view.object.find_significant_nodes_without_descending(:method_override).first
          @view.prepend(method_override_input)
          input = @view.object.find_significant_nodes_without_descending(:method_override).first
        end

        input
      end

      def authenticity_token_input(token, param:)
        safe("<input type=\"hidden\" name=\"#{param}\" value=\"#{token}\">")
      end

      def origin_input(origin)
        safe("<input type=\"hidden\" name=\"form[origin]\" value=\"#{origin}\">")
      end

      def id_input(id)
        safe("<input type=\"hidden\" name=\"form[id]\" value=\"#{id}\">")
      end

      def binding_input
        safe("<input type=\"hidden\" name=\"form[binding]\" value=\"#{[@view.label(:binding)].concat(@view.label(:channel)).join(":")}\">")
      end

      def create_select_options(values, field_view)
        options = Oga::XML::Document.new

        values.each do |value|
          options.children << create_select_option(value)
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
            group.children << create_select_option(value)
          end
        end

        add_options_to_select(options, field_view)
      end

      def create_select_option(value)
        Oga::XML::Element.new(name: "option").tap do |option|
          option.set("value", ensure_html_safety(value[0].to_s))
          option.inner_text = ensure_html_safety(value[1].to_s)
        end
      end

      def create_input_options(values, field_view)
        template = field_view.dup
        insertable = field_view
        current = field_view

        values.each do |value|
          if field_view.attributes[:type] == "checkbox"
            current.attributes[:name] = "#{current.attributes[:name]}[]"
          end

          current.attributes[:value] = value[0]

          unless current.equal?(field_view)
            insertable.after(current)
            insertable = current
          end

          current = template.dup
        end
      end

      def options_for_allowed?(field_view)
        field_view.object.tagname == "select" || (
          field_view.object.tagname == "input" && (
            field_view.object.attributes[:type] == "checkbox" || field_view.object.attributes[:type] == "radio"
          )
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
    end
  end
end
