require "forwardable"

module Pakyow
  module Presenter
    class View
      class << self
        # Creates a view from a file.
        #
        def load(path)
          new(File.read(path))
        end
      end

      extend Forwardable

      def_delegators :@object, :title=, :title, :text, :html, :to_html, :to_s

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :object

      # Creates a view with +html+.
      #
      # FIXME: only accept html here, create #from_object method
      def initialize(html = "", object: nil)
        @info = {}
        @info, html = FrontMatterParser.parse_and_scrub(html) unless html.empty?

        @object = object ? object : StringDoc.new(html)
      end

      def initialize_copy(_)
        super
        @object = object.dup
      end

      def find(*names)
        name = names.shift

        found = @object.find_significant_nodes_with_name(:prop, name, with_children: false).concat(@object.find_significant_nodes_with_name(:scope, name)).each_with_object(ViewCollection.new(scoped_as: name)) { |significant, collection|
          collection << View.new(object: significant)
        }

        if names.empty?
          found
        else
          found.find(*names)
        end
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with
        yield self; self
      end

      def info(key = nil)
        return @info if key.nil?
        return @info[key]
      end

      def add_info(*infos)
        infos.each do |info|
          @info.merge!(Hash.symbolize(info))
        end

        self
      end

      def container(name)
        @object.find_significant_nodes(:container, name)[0]
      end

      def partial(name)
        @object.find_significant_nodes(:partial, name).each_with_object(ViewCollection.new) { |partial, collection|
          collection << View.new(object: partial)
        }
      end

      def component(name)
        @object.find_significant_nodes(:component, name).each_with_object(ViewCollection.new) { |component, collection|
          collection << View.new(object: component)
        }
      end

      def form(name)
        # TODO:
      end

      def transform(object)
        # TODO: should transform recursively through `object`

        if object.nil?
          remove
        else
          props.each do |prop|
            next if object.key?(prop.name)
            prop.remove
          end
        end

        yield self, object if block_given?

        self
      end

      # call-seq:
      #   bind(data)
      #
      # Binds a single datum across existing scopes.
      #
      def bind(object)
        # TODO: should bind recursively through `object`

        bind_data_to_scope(object)
        attrs.send(:"data-id=", object[:id])
        yield self, object if block_given?
        self
      end

      # call-seq:
      #   apply(data)
      #
      # Transform self to object then binds object to the view.
      #
      def present(object)
        transform(object).bind(object)
      end

      def append(view)
        # TODO: handle string / collection
        @object.append(view.object)
        self
      end

      def prepend(view)
        # TODO: handle string / collection
        @object.prepend(view.object)
        self
      end

      def after(view)
        # TODO: handle string / collection
        @object.after(view.object)
        self
      end

      def before(view)
        # TODO: handle string / collection
        @object.before(view.object)
        self
      end

      def replace(view)
        # TODO: handle string / collection
        @object.replace(view.object)
        self
      end

      def remove
        @object.remove
        self
      end

      def clear
        @object.clear
        self
      end

      def text=(text)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        text = text.call(self.text) if text.is_a?(Proc)
        @object.text = text
      end

      def html=(html)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        html = html.call(self.html) if html.is_a?(Proc)
        @object.html = html
      end

      def ==(other)
        other.is_a?(self.class) && @object == other.object
      end

      # TODO: replaced with name/type
      def scoped_as
        @object.name
      end

      # Allows multiple attributes to be set at once.
      #
      #   view.attrs(class: '...', style: '...')
      #
      def attrs(attrs = {})
        return Attributes.new(@object) if attrs.empty?
        bind_attributes_to_object(attrs, @object)
      end

      # @api private
      def scopes
        @object.find_significant_nodes(:scope)
      end

      # @api private
      def props
        @object.find_significant_nodes(:prop, with_children: false)
      end

      # @api private
      def mixin(partials)
        object.find_significant_nodes(:partial).each do |partial_node|
          next unless partial = partials[partial_node.name]

          replacement = partial
          replacement.mixin(partials)

          partial_node.replace(replacement.object)
        end

        self
      end

      private

      # TODO: probably a concern of presenter
      # def adjust_value_parts(value, parts)
      #   return value unless value.is_a?(Hash)

      #   parts_to_keep = parts.fetch(:include, value.keys)
      #   parts_to_keep -= parts.fetch(:exclude, [])

      #   value.keep_if { |part, _| parts_to_keep.include?(part) }
      # end

      def bind_data_to_scope(data)
        return unless data

        # TODO: root bindings should be handled in the binder, not here
        # bind_data_to_root(data)

        props.each do |prop|
          # TODO: should be handled explicitly by a form object
          # if DocHelpers.form_field?(object.tagname)
          #   set_form_field_name(prop, prop.name)
          # end

          if data.include?(prop.name)
            value = data[prop.name]

            # TODO: should be handled explicitly by a form object
            # if DocHelpers.form_field?(object.tagname)
            #   bind_to_form_field(prop, prop.name, value, data)
            # end

            bind_data_to_object(prop, value)
          else
            # TODO: do we want to remove the node here?
            # handle_unbound_data(prop.name)
          end
        end
      end

      # ROOT = :_root # TODO: reconsider if this should have an underscore
      # def bind_data_to_root(data)
      #   return unless data.is_a?(Binder) && data.include?(ROOT) && value = data[ROOT]
      #   value.is_a?(Hash) ? bind_attributes_to_object(value, object) : bind_value_to_object(value, object)
      # end

      def bind_data_to_object(object, data)
        data.is_a?(Hash) ? bind_attributes_to_object(data, object) : bind_value_to_object(data, object)
      end

      def bind_value_to_object(value, object)
        value = String(value)

        tag = object.tagname
        return if StringNode.without_value?(tag)

        if StringNode.self_closing?(tag)
          # don't override value if set
          if !object.get_attribute(:value) || object.get_attribute(:value).empty?
            object.set_attribute(:value, value)
          end
        else
          object.html = value
        end
      end

      # def bind_to_form_field(object, scope, prop, value, bindable)
      #   # special binding for checkboxes and radio buttons
      #   if object.tagname == 'input' && (object.get_attribute(:type) == 'checkbox' || object.get_attribute(:type) == 'radio')
      #     bind_to_checked_field(object, value)
      #     # special binding for selects
      #   elsif object.tagname == 'select'
      #     bind_to_select_field(object, scope, prop, value, bindable)
      #   end
      # end

      # def bind_to_checked_field(object, value)
      #   if value == true || (object.get_attribute(:value) && object.get_attribute(:value) == value.to_s)
      #     object.set_attribute(:checked, 'checked')
      #   else
      #     object.remove_attribute(:checked)
      #   end

      #   # coerce to string since booleans are often used and fail when binding to a view
      #   value.to_s
      # end

      # def bind_to_select_field(object, scope, prop, value, bindable)
      #   create_select_options(object, scope, prop, value, bindable)
      #   select_option_with_value(object, value)
      # end

      # def set_form_field_name(object, scope, prop)
      #   return if object.get_attribute(:name) && !object.get_attribute(:name).empty? # don't overwrite the name if already defined
      #   object.set_attribute(:name, "#{scope}[#{prop}]")
      # end

      # TODO: probably a concern of presenter
      # def create_select_options(object, scope, prop, value, bindable)
      #   options = Binder.options_for_scoped_prop(scope, prop, bindable)
      #   return if options.nil?

      #   nodes = Oga::XML::Document.new

      #   until options.length == 0
      #     catch :optgroup do
      #       o = options.first

      #       # an array containing value/content
      #       if o.is_a?(Array)
      #         node = Oga::XML::Element.new(name: 'option')
      #         node.inner_text = o[1].to_s
      #         node.set('value', o[0].to_s)
      #         nodes.children << node
      #         options.shift
      #       else # likely an object (e.g. string); start a group
      #         node_group = Oga::XML::Element.new(name: 'optgroup')
      #         node_group.set('label', o.to_s)
      #         nodes.children << node_group

      #         options.shift

      #         options[0..-1].each_with_index { |o2,i2|
      #           # starting a new group
      #           throw :optgroup unless o2.is_a?(Array)

      #           node = Oga::XML::Element.new(name: 'option')
      #           node.inner_text = o2[1].to_s
      #           node.set('value', o2[0].to_s)
      #           node_group.children << node
      #           options.shift
      #         }
      #       end
      #     end
      #   end

      #   # remove existing options
      #   object.clear

      #   # add generated options
      #   object.append(nodes.to_xml)
      # end

#       def select_option_with_value(object, value)
#         option = object.option(value: value)
#         return if option.nil?

#         option.set_attribute(:selected, 'selected')
#       end

      def handle_unbound_data(scope, prop = nil)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]") if Pakyow.logger
        throw :unbound
      end

      # TODO: this shouldn't handle content; probably can be simplified
      # TODO: shouldn't this be handled by the attributes object?
      def bind_attributes_to_object(attrs, object)
        attrs.each do |attr, v|
          case attr
          when :content
            v = v.call(object.html) if v.is_a?(Proc)
            bind_value_to_object(v, object)
          when :view
            v.call(View.new(object: object))
          else
            attr  = attr.to_s
            attrs = Attributes.new(object)

            if v.is_a?(Proc)
              attribute = attrs.send(attr)
              ret = v.call(attribute)
              value = ret.respond_to?(:value) ? ret.value : ret

              attrs.send("#{attr}=", value)
            elsif v.nil?
              object.remove_attribute(attr)
            else
              attrs.send("#{attr}=", v)
            end
          end
        end
      end
    end
  end
end
