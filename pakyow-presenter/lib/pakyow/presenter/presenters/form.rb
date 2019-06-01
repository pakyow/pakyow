# frozen_string_literal: true

require "securerandom"

require "pakyow/support/core_refinements/array/ensurable"
require "pakyow/support/inflector"
require "pakyow/support/safe_string"

require "pakyow/presenter/presenter"
require "pakyow/presenter/presenters/endpoint"

module Pakyow
  module Presenter
    module Presenters
      class Form < DelegateClass(Presenter)
        class << self
          # @api private
          def pluralize_field_name(field)
            unless field.attributes[:name].to_s.end_with?("[]") || field.attributes[:name].to_s.empty?
              field.attributes[:name] = "#{field.attributes[:name]}[]"
            end
          end

          # @api private
          def connect_input_to_label(input, label)
            if false || input.attributes[:id].to_s.empty?
              id = SecureRandom.hex(4)
              input.attributes[:id] = id
            else
              id = input.attributes[:id]
            end

            label.attributes[:for] = id
          end
        end

        using Support::Refinements::Array::Ensurable

        include Support::SafeStringHelpers

        SUPPORTED_ACTIONS = %i(create update replace delete).freeze
        ACTION_METHODS = { create: "post", update: "patch", replace: "put", delete: "delete" }.freeze

        # @api private
        ID_LABEL = :__form_id

        def object_for_form
          if labeled?(:binding)
            presentables[channeled_binding_name]
          end
        end

        def id
          label(ID_LABEL)
        end

        # Sets the form action (where it submits to).
        #
        def action=(action)
          if action.is_a?(Symbol)
            if endpoint = app.endpoints.find(name: action)
              view.object.set_label(:endpoint, action)
              view.object.set_label(:endpoint_object, endpoint)
              view.object.set_label(:endpoint_params, {})
            end
          else
            attrs[:action] = action
          end
        end

        # Sets the form method. Automatically handles method overrides by prepending a hidden field
        # named `_method` when +method+ is not get or post, setting the form method to +post+.
        #
        def method=(method)
          method = method.to_s.downcase
          if method_override_required?(method)
            attrs[:method] = "post"

            find_or_create_method_override_input.attributes[:value] = method
          else
            attrs[:method] = method
          end
        end

        # Populates a select field with options.
        #
        def options_for(field, options = nil)
          unless field_presenter = find(field) || find(Support.inflector.singularize(field)) || find(Support.inflector.pluralize(field))
            raise ArgumentError.new("could not find field named `#{field}'")
          end

          unless options_for_allowed?(field_presenter)
            raise ArgumentError.new("expected `#{field}' to be a select field, checkbox, radio button, or binding")
          end

          options = if block_given?
            yield(field_presenter)
          else
            options
          end

          case field_presenter.object.tagname
          when "select"
            create_select_options(options, field_presenter)
          when "input"
            create_input_options(options, field_presenter)
          else
            create_options(options, field_presenter)
          end
        end

        # Populates a select field with grouped options.
        #
        def grouped_options_for(field, options = nil)
          unless field_presenter = find(field)
            raise ArgumentError.new("could not find field named `#{field}'")
          end

          unless grouped_options_for_allowed?(field_presenter)
            raise ArgumentError.new("expected `#{field}' to be a select field")
          end

          options = options || yield
          case field_presenter.object.tagname
          when "select"
            create_grouped_select_options(options, field_presenter)
          end
        end

        def setup(object = {})
          use_binding_nodes
          use_global_options

          if block_given?
            yield self
          end

          bind(object)

          if labeled?(:endpoint)
            Endpoint.new(__getobj__).setup
          end

          setup!
          self
        end

        def setup?
          view.object.labeled?(:__form_setup)
        end

        private def setup!
          view.object.set_label(:__form_setup, true)
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

        # Fixes an issue using pp inside a delegator.
        #
        def pp(*args)
          Kernel.pp(*args)
        end

        # Delegate private methods.
        #
        def method_missing(method_name, *args, &block)
          __getobj__.send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          super || __getobj__.respond_to?(method_name, true)
        end

        private

        def setup_form_for_binding(action, object)
          setup(object) do
            if SUPPORTED_ACTIONS.include?(action)
              unless labeled?(:endpoint)
                if self.action = form_action_for_binding(action, object)
                  self.method = method_for_action(action)
                end
              end
            else
              raise ArgumentError.new("expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}")
            end
          end
        end

        def use_binding_nodes
          view.object.set_label(:used, true)
          view.object.children.each_significant_node(:binding, descend: true) do |object|
            object.set_label(:used, true)
          end
        end

        def use_global_options
          __getobj__.class.__global_options.each do |form_binding, options|
            form = if view.object.tagname == "form" && view.binding_name == form_binding
              self
            else
              form(form_binding)
            end

            if form
              options.each do |field_binding, metadata|
                if metadata[:block]
                  form.options_for(field_binding) do |context|
                    instance_exec(context, &metadata[:block])
                  end
                else
                  form.options_for(field_binding, metadata[:options])
                end
              end
            end
          end
        end

        def form_action_for_binding(action, object)
          [
            Support.inflector.singularize(label(:binding)).to_sym,
            Support.inflector.pluralize(label(:binding)).to_sym
          ].map { |possible_endpoint_name|
            app.endpoints.path_to(possible_endpoint_name, action, object.to_h)
          }.compact.first
        end

        def method_for_action(action)
          ACTION_METHODS[action]
        end

        def method_override_required?(method)
          method != "get" && method != "post"
        end

        def method_override_input
          html_safe("<input type=\"hidden\" name=\"_method\">")
        end

        def find_or_create_method_override_input
          unless input = view.object.find_first_significant_node(:method_override)
            prepend(method_override_input)
            input = view.object.find_first_significant_node(:method_override)
          end

          input
        end

        def create_select_options(values, field_presenter)
          options = Oga::XML::Document.new

          Array.ensure(values).compact.each do |value|
            options.children << create_select_option(value, field_presenter)
          end

          add_options_to_select(options, field_presenter)
        end

        def create_grouped_select_options(values, field_presenter)
          options = Oga::XML::Document.new

          values.each do |group_name, grouped_values|
            group = Oga::XML::Element.new(name: "optgroup")
            group.set("label", ensure_html_safety(group_name.to_s))
            options.children << group

            grouped_values.each do |value|
              group.children << create_select_option(value, field_presenter)
            end
          end

          add_options_to_select(options, field_presenter)
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

        def create_input_options(values, field_presenter)
          if values.is_a?(Array) && field_presenter.attributes[:type] != "radio"
            self.class.pluralize_field_name(field_presenter.object)
          end

          values = Array.ensure(values).compact

          if values.any?
            field_view = Pakyow::Presenter::Form.from_object(field_presenter.view.object)
            field_template = field_view.dup
            insertable_field = field_view
            current_field = field_view

            values.each do |value|
              current_field.attributes[:value] = option_value(value, field_presenter.view).to_s

              unless current_field.equal?(field_view)
                insertable_field.after(current_field)
                insertable_field = current_field
              end

              current_field = field_template.dup
            end
          else
            field_presenter.remove
          end
        end

        def create_options(original_values, field_presenter)
          values = Array.ensure(original_values).compact

          if values.any?
            field_view = Pakyow::Presenter::Form.from_object(field_presenter.view.object)
            template = field_view.dup
            insertable = field_view
            current = field_view

            values.each do |value|
              if treat_as_nested?(current, value)
                # We bind to a view here to avoid checking the value when setting up the option.
                #
                View.from_object(current.object).bind(value)

                # Set the field names appropriately.
                #
                current.object.each_significant_node(:field) do |field|
                  name = "#{view.object.label(:binding)}[#{current.label(:binding)}]"
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
                  name = "#{view.object.label(:binding)}[#{current.label(:binding)}]"
                  name = if original_values.is_a?(Array)
                    "#{name}[][#{key}]"
                  else
                    "#{name}[#{key}]"
                  end
                  id_input.set(:name, name)
                  id_input.set(:value, ensure_html_safety(value[key].to_s))
                  current.prepend(html_safe(id_input.to_xml))
                end
              else
                if input = current.object.find_first_significant_node(:field)
                  input.attributes[:name] = "#{view.object.label(:binding)}[#{current.label(:binding)}]"

                  if original_values.is_a?(Array) && input.attributes[:type] != "radio"
                    self.class.pluralize_field_name(input)
                  end

                  input.attributes[:value] = ensure_html_safety(option_value(value, current).to_s)
                end

                if label = current.object.find_first_significant_node(:label)
                  label.html = ensure_html_safety(label_value(value, label).to_s)
                end

                if input && label
                  self.class.connect_input_to_label(input, label)
                end
              end

              unless current.equal?(field_view)
                insertable.after(current)
                insertable = current
              end

              current = template.dup
            end
          else
            field_presenter.remove
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

        def options_for_allowed?(field_presenter)
          field_presenter.object.tagname == "select" || (
            field_presenter.object.tagname == "input" && (
              field_presenter.object.attributes[:type] == "checkbox" || field_presenter.object.attributes[:type] == "radio"
            ) ||
            field_presenter.object.significant?(:binding)
          )
        end

        def grouped_options_for_allowed?(field_presenter)
          field_presenter.object.tagname == "select"
        end

        def add_options_to_select(options, field_presenter)
          # remove existing options
          field_presenter.clear

          # add generated options
          field_presenter.append(html_safe(options.to_xml))
        end
      end
    end
  end
end
