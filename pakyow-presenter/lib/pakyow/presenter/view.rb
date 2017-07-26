require 'forwardable'

module Pakyow
  module Presenter
    class View
      extend Forwardable

      def_delegators :@object, :title=, :title, :remove, :clear, :text, :html

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :object

      # Creates a view with +html+.
      #
      def initialize(html = "", object: nil)
        @object = object ? object : StringDoc.new(html)
      end

      def initialize_copy(original)
        super
        @object = object.dup
      end

      # Creates a view from a file.
      #
      def self.load(path)
        new(File.read(path))
      end

      def container(name)
        object.container(name)
      end

      def ==(other)
        # TODO: revisit this
        self.class == other.class && @object == other.object
      end

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

      def append(view)
        @object.append(view.object)
      end

      def prepend(view)
        @object.prepend(view.object)
      end

      def after(view)
        @object.after(view.object)
      end

      def before(view)
        @object.before(view.object)
      end

      def replace(view)
        replacement = view.is_a?(View) ? view.object : view
        @object.replace(replacement)
      end

      # TODO: replace with `find`
      def scope(name)
        @object.scope(name.to_sym).inject(ViewCollection.new(scoped_as: name)) do |coll, scope|
          coll << View.new(object: scope)
        end
      end

      # TODO: replace with `find`
      def prop(name)
        @object.prop(name.to_sym).inject(ViewCollection.new) do |coll, prop|
          coll << View.new(object: prop[:object])
        end
      end

      def component(name)
        @object.component(name.to_sym).inject(ViewCollection.new) do |coll, component|
          coll << View.new(object: component[:object])
        end
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with(&block)
        if block.arity == 0
          instance_exec(&block)
        else
          yield(self)
        end

        self
      end

      # call-seq:
      #   for {|view, datum| block}
      #
      # Yields a view and its matching dataum. This is driven by the view,
      # meaning datums are yielded until no more views are available. For
      # the single View case, only one view/datum pair is yielded.
      #
      # (this is basically Bret's `map` function)
      #
      def for(data, &block)
        datum = Array.ensure(data).first
        if block.arity == 1
          instance_exec(datum, &block)
        else
          block.call(self, datum)
        end
      end

      # call-seq:
      #   for_with_index {|view, datum, i| block}
      #
      # Yields a view, its matching dataum, and the index. See #for.
      #
      def for_with_index(data, &block)
       self.for(data) do |ctx, datum|
          if block.arity == 2
            ctx.instance_exec(datum, 0, &block)
          else
            block.call(ctx, datum, 0)
          end
        end
      end

      # call-seq:
      #   match(data) => ViewCollection
      #
      # Returns a ViewCollection object that has been manipulated to match the data.
      # For the single View case, the ViewCollection collection will consist n copies
      # of self, where n = data.length.
      #
      def match(data)
        data = Array.ensure(data)
        coll = ViewCollection.new

        # an empty set always means an empty view
        if data.empty?
          remove
        else
          # the original view match the first datum
          coll << self

          working = self

          # create views for the other datums
          data[1..-1].inject(coll) { |set|
            duped_view = working.dup
            working.after(duped_view)
            working = duped_view
            set << duped_view
          }
        end

        # return the new collection
        coll
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Matches self with data and yields a view/datum pair.
      #
      def repeat(data, &block)
        match(data).for(data, &block)
      end

      # call-seq:
      #   repeat_with_index(data) {|view, datum, i| block}
      #
      # Matches self with data and yields a view/datum pair with index.
      #
      def repeat_with_index(data, &block)
        match(data).for_with_index(data, &block)
      end

      # call-seq:
      #   bind(data)
      #
      # Binds a single datum across existing scopes.
      #
      def bind(data, &block)
        datum = Array.ensure(data).first
        bind_data_to_scope(datum)

        id = nil
        if data.is_a?(Hash)
          id = data[:id]
        elsif data.respond_to?(:id)
          id = data.id
        end

        attrs.send(:'data-id=', data[:id]) unless id.nil?
        return if block.nil?

        if block.arity == 1
          instance_exec(datum, &block)
        else
          block.call(self, datum)
        end

        self
      end

      # call-seq:
      #   bind_with_index(data)
      #
      # Binds data across existing scopes, yielding a view/datum pair with index.
      #
      def bind_with_index(*a, **k, &block)
        bind(*a, **k) do |ctx, datum|
          if block.arity == 2
            ctx.instance_exec(datum, 0, &block)
          else
            block.call(ctx, datum, 0)
          end
        end
      end

      # call-seq:
      #   apply(data)
      #
      # Matches self to data then binds data to the view.
      #
      def apply(data, &block)
        match(data).bind(data, &block)
      end

      def mixin(partial_map)
        object.mixin(partial_map); self
      end

			def to_html
				@object.to_html
			end
      alias :to_s :to_html

      def component?
        !attrs.send(:'data-ui').value.empty?
      end

      def component_name
        return unless component?
        attrs.send(:'data-ui').value
      end

      # Convenience method for parity with Presenter::ViewCollection.
      #
      def length
        1
      end

      # Convenience method for parity with Presenter::ViewCollection.
      #
      def first
        self
      end

      private

      # TODO: probably a concern of presenter
      def adjust_value_parts(value, parts)
        return value unless value.is_a?(Hash)

        parts_to_keep = parts.fetch(:include, value.keys)
        parts_to_keep -= parts.fetch(:exclude, [])

        value.keep_if { |part, _| parts_to_keep.include?(part) }
      end

      def bind_data_to_scope(data)
        return unless data

        bind_data_to_root(data)

        object.props.each do |name, props|
          props.each do |prop|
            catch :unbound do
              if StringNode.form_input?(object.tagname)
                set_form_field_name(prop, prop.name)
              end

              if data_has_prop?(data, prop.name)
                value = data[prop.name]

                if StringNode.form_input?(object.tagname)
                  bind_to_form_field(prop, prop.name, value, data)
                end

                bind_data_to_object(prop, value)
              else
                handle_unbound_data(prop.name)
              end
            end
          end
        end
      end

      ROOT = :_root # TODO: reconsider if this should have an underscore
      def bind_data_to_root(data)
        return unless data.is_a?(Binder) && data.include?(ROOT) && value = data[ROOT]
        value.is_a?(Hash) ? bind_attributes_to_object(value, object) : bind_value_to_object(value, object)
      end

      def bind_data_to_object(object, data)
        data.is_a?(Hash) ? bind_attributes_to_object(data, object) : bind_value_to_object(data, object)
      end

      def data_has_prop?(data, prop)
        data.include?(prop)
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

      def bind_to_form_field(object, scope, prop, value, bindable)
        # special binding for checkboxes and radio buttons
        if object.tagname == 'input' && (object.get_attribute(:type) == 'checkbox' || object.get_attribute(:type) == 'radio')
          bind_to_checked_field(object, value)
          # special binding for selects
        elsif object.tagname == 'select'
          bind_to_select_field(object, scope, prop, value, bindable)
        end
      end

      def bind_to_checked_field(object, value)
        if value == true || (object.get_attribute(:value) && object.get_attribute(:value) == value.to_s)
          object.set_attribute(:checked, 'checked')
        else
          object.remove_attribute(:checked)
        end

        # coerce to string since booleans are often used and fail when binding to a view
        value.to_s
      end

      def bind_to_select_field(object, scope, prop, value, bindable)
        create_select_options(object, scope, prop, value, bindable)
        select_option_with_value(object, value)
      end

      def set_form_field_name(object, scope, prop)
        return if object.get_attribute(:name) && !object.get_attribute(:name).empty? # don't overwrite the name if already defined
        object.set_attribute(:name, "#{scope}[#{prop}]")
      end

      # TODO: probably a concern of presenter
      def create_select_options(object, scope, prop, value, bindable)
        options = Binder.options_for_scoped_prop(scope, prop, bindable)
        return if options.nil?

        nodes = Oga::XML::Document.new

        until options.length == 0
          catch :optgroup do
            o = options.first

            # an array containing value/content
            if o.is_a?(Array)
              node = Oga::XML::Element.new(name: 'option')
              node.inner_text = o[1].to_s
              node.set('value', o[0].to_s)
              nodes.children << node
              options.shift
            else # likely an object (e.g. string); start a group
              node_group = Oga::XML::Element.new(name: 'optgroup')
              node_group.set('label', o.to_s)
              nodes.children << node_group

              options.shift

              options[0..-1].each_with_index { |o2,i2|
                # starting a new group
                throw :optgroup unless o2.is_a?(Array)

                node = Oga::XML::Element.new(name: 'option')
                node.inner_text = o2[1].to_s
                node.set('value', o2[0].to_s)
                node_group.children << node
                options.shift
              }
            end
          end
        end

        # remove existing options
        object.clear

        # add generated options
        object.append(nodes.to_xml)
      end

      def select_option_with_value(object, value)
        option = object.option(value: value)
        return if option.nil?

        option.set_attribute(:selected, 'selected')
      end

      def handle_unbound_data(scope, prop = nil)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]") if Pakyow.logger
        throw :unbound
      end

      # TODO: this shouldn't handle content; probably can be simplified
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
