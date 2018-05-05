# frozen_string_literal: true

require "securerandom"

require "pakyow/presenter/presenter"
require "pakyow/presenter/behavior/endpoints/form"

module Pakyow
  module Presenter
    # Presents a form.
    #
    class FormPresenter < Presenter
      SUPPORTED_ACTIONS = %i(create update replace remove).freeze
      ACTION_METHODS = { create: "post", update: "patch", replace: "put", remove: "delete" }.freeze

      include Behavior::Endpoints::Form

      # @api private
      ID_LABEL = :__form_id

      def initialize(*)
        super

        unless @view.labeled?(ID_LABEL)
          id = SecureRandom.hex(24)
          @view.object.add_label(ID_LABEL, id)
        end

        setup_field_names
      end

      def id
        @view.label(ID_LABEL)
      end

      # Sets the form action (where it submits to).
      #
      def action=(action)
        @view.attrs[:action] = action
      end

      # Sets the form method. Automatically handles method overrides by prepending a hidden field
      # named `_method` when +method+ is not get or post, setting the form method to +post+.
      #
      def method=(method)
        method = method.to_s.downcase

        if method_override_required?(method)
          @view.attrs[:method] = "post"
          @view.prepend(method_override_input(method))
        else
          @view.attrs[:method] = method
        end
      end

      # Populates a select field with options.
      #
      def options_for(field, options = nil)
        create_select_options(field, options || yield)
      end

      # Populates a select field with grouped options.
      #
      def grouped_options_for(field, grouped_options = nil)
        create_grouped_select_options(field, grouped_options || yield)
      end

      # Setup the form for creating an object.
      #
      def create(object)
        yield self if block_given?
        setup_form :create, object
      end

      # Setup the form for updating an object.
      #
      def update(object)
        yield self if block_given?
        setup_form :update, object
      end

      # Setup the form for replacing an object.
      #
      def replace(object)
        yield self if block_given?
        setup_form :replace, object
      end

      # Setup the form for removing an object.
      #
      def remove(object)
        yield self if block_given?
        setup_form :remove, object
      end

      def embed_authenticity_token(token, param:)
        @view.prepend(authenticity_token_input(token, param: param))
      end

      protected

      def setup_form(action, object)
        action = action.to_sym
        if SUPPORTED_ACTIONS.include?(action)
          self.method = method_for_action(action)
          @view.bind(object)
        else
          raise ArgumentError.new("Expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}")
        end
      end

      def setup_field_names
        @view.object.children.find_significant_nodes(:binding).each do |binding_node|
          binding_node.attributes[:name] ||= "#{@view.object.label(:binding)}[#{binding_node.label(:binding)}]"
        end
      end

      def method_for_action(action)
        ACTION_METHODS[action]
      end

      def method_override_required?(method)
        method != "get" && method != "post"
      end

      def method_override_input(method)
        safe("<input type=\"hidden\" name=\"_method\" value=\"#{method}\">")
      end

      def authenticity_token_input(token, param:)
        safe("<input type=\"hidden\" name=\"#{param}\" value=\"#{token}\">")
      end

      def create_select_options(field, values)
        options = Oga::XML::Document.new

        values.each do |value|
          options.children << create_select_option(value)
        end

        add_options_to_field(options, field)
      end

      def create_grouped_select_options(field, values)
        options = Oga::XML::Document.new

        values.each do |group_name, grouped_values|
          group = Oga::XML::Element.new(name: "optgroup")
          group.set("label", ensure_html_safety(group_name.to_s))
          options.children << group

          grouped_values.each do |value|
            group.children << create_select_option(value)
          end
        end

        add_options_to_field(options, field)
      end

      def create_select_option(value)
        Oga::XML::Element.new(name: "option").tap do |option|
          option.set("value", ensure_html_safety(value[0].to_s))
          option.inner_text = ensure_html_safety(value[1].to_s)
        end
      end

      def add_options_to_field(options, field)
        unless field_view = @view.find(field)
          raise ArgumentError.new("Could not find field named `#{field}`")
        end

        unless field_view.object.tagname == "select"
          raise ArgumentError.new("Expected `#{field}` to be a select field")
        end

        # remove existing options
        field_view.clear

        # add generated options
        field_view.append(safe(options.to_xml))
      end
    end
  end
end
