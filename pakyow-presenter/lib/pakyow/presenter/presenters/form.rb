require "pakyow/presenter/presenter"

module Pakyow
  module Presenter
    class FormPresenter < Presenter
      METHOD_OVERRIDES = {
        update: "patch".freeze,
        replace: "put".freeze,
        remove: "delete".freeze
      }.freeze

      SUPPORTED_ACTIONS = %i(create update replace remove)

      FORM_METHOD_DEFAULT = "post".freeze

      def setup(action, object = nil)
        action = action.to_sym

        raise ArgumentError.new("Expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}") unless SUPPORTED_ACTIONS.include?(action)

        yield self if block_given?

        @view.attrs.method = FORM_METHOD_DEFAULT
        @view.attrs.action = form_action(action, object)

        if method_override_required?(action)
          @view.prepend(method_override_input(action))
        end

        if object
          @view.bind(object)
        end

        set_input_names
      end

      def create(object)
        yield self if block_given?
        setup :create, object
      end

      def update(object)
        yield self if block_given?
        setup :update, object
      end

      def replace(object)
        yield self if block_given?
        setup :replace, object
      end

      def remove(object)
        yield self if block_given?
        setup :remove, object
      end

      def options_for(field, options = nil)
        create_select_options(field, options ||= yield)
      end

      def value_for(field, value = nil)
        set_value(field, value ||= yield)
      end

      protected

      def form_action(action, object)
        @path_builder.path_to(@view.name, action, **form_action_params(object))
      end

      def form_action_params(object)
        params = {}
        params[:"#{@view.name}_id"] = object[:id] if object
        params
      end

      def method_override_required?(action)
        METHOD_OVERRIDES.include?(action)
      end

      def method_override(action)
        METHOD_OVERRIDES[action]
      end

      def method_override_input(action)
        # FIXME: avoid creating a new view once string values are supported (there's no need to parse)
        View.new("<input type=\"hidden\" name=\"_method\" value=\"#{method_override(action)}\">")
      end

      def set_input_names
        @view.props.each do |prop|
          prop.attributes[:name] = "#{@view.name}[#{prop.name}]" if prop.attributes[:name].nil?
        end
      end

      def create_select_options(field, values)
        option_nodes = Oga::XML::Document.new

        until values.length == 0
          catch :optgroup do
            o = values.first

            # an array containing value/content
            if o.is_a?(Array)
              node = Oga::XML::Element.new(name: 'option')
              node.inner_text = ensure_html_safety(o[1].to_s)
              node.set('value', ensure_html_safety(o[0].to_s))
              option_nodes.children << node
              values.shift
            else # likely an object (e.g. string); start a group
              node_group = Oga::XML::Element.new(name: 'optgroup')
              node_group.set('label', ensure_html_safety(o.to_s))
              option_nodes.children << node_group

              values.shift

              values[0..-1].each_with_index { |o2,i2|
                # starting a new group
                throw :optgroup unless o2.is_a?(Array)

                node = Oga::XML::Element.new(name: 'option')
                node.inner_text = ensure_html_safety(o2[1].to_s)
                node.set('value', ensure_html_safety(o2[0].to_s))
                node_group.children << node
                values.shift
              }
            end
          end
        end

        field_view = @view.find(field)[0]
        raise ArgumentError.new("Couldn't find a field named #{field}") if field_view.nil?

        # remove existing options
        field_view.clear

        # add generated options
        # FIXME: avoid creating a new view once string values are supported (there's no need to parse)
        # we can also build up options as an html string rather than an oga document
        field_view.append(View.new(option_nodes.to_xml))
      end

      def set_value(field, value)
        field_view = @view.find(field)[0]
        raise ArgumentError.new("Couldn't find a field named #{field}") if field_view.nil?
        raise ArgumentError.new("Expected #{field} to be of type checkbox or radio") unless Form::CHECKED_TYPES.include?(field_view.object.attributes[:type])

        field_view.object.attributes[:value] = value
      end
    end
  end
end
