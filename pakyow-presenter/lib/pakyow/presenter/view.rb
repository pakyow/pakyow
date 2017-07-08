require 'forwardable'

module Pakyow
  module Presenter
    class View
      extend Forwardable

      def_delegators :@doc, :title=, :title, :remove, :clear, :text, :html, :exists?

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :doc

      # Creates a view with +html+.
      #
      def initialize(html = "", doc: nil)
        @doc = doc ? doc : StringDoc.new(html)
      end

      def initialize_copy(original)
        super
        @doc = doc.dup
      end

      # Creates a view from a file.
      #
      def self.load(path)
        new(File.read(path))
      end

      def ==(other)
        # TODO: revisit this
        self.class == other.class && @doc == other.doc
      end

      def scoped_as
        @doc.name
      end

      # Allows multiple attributes to be set at once.
      #
      #   view.attrs(class: '...', style: '...')
      #
      def attrs(attrs = {})
        return Attributes.new(@doc) if attrs.empty?
        bind_attributes_to_doc(attrs, @doc)
      end

      def text=(text)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        text = text.call(self.text) if text.is_a?(Proc)
        @doc.text = text
      end

      def html=(html)
        # FIXME: IIRC we support this for bindings; seems like a weird thing to do here
        html = html.call(self.html) if html.is_a?(Proc)
        @doc.html = html
      end

      def append(view)
        @doc.append(view.doc)
      end

      def prepend(view)
        @doc.prepend(view.doc)
      end

      def after(view)
        @doc.after(view.doc)
      end

      def before(view)
        @doc.before(view.doc)
      end

      def replace(view)
        replacement = view.is_a?(View) ? view.doc : view
        @doc.replace(replacement)
      end

      def scope(name)
        @doc.scope(name.to_sym).inject(ViewCollection.new) do |coll, scope|
          coll << View.new(doc: scope)
        end
      end

      def prop(name)
        @doc.prop(name.to_sym).inject(ViewCollection.new) do |coll, prop|
          coll << View.new(doc: prop[:doc])
        end
      end

      # def version
      #   return unless versioned?
      #   @doc.get_attribute(:'data-version').to_sym
      # end
      #
      # def versioned?
      #   !@doc.get_attribute(:'data-version').nil?
      # end

      def component(name)
        name = name.to_sym
        @doc.component(name).inject(ViewCollection.new) do |coll, component|
          coll << View.new(doc: component[:doc])
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
        doc.mixin(partial_map); self
      end

			def to_html
				@doc.to_html
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

        doc.props.each do |name, props|
          props.each do |prop|
            catch :unbound do
              if DocHelpers.form_field?(doc.tagname)
                set_form_field_name(prop, prop.name)
              end

              if data_has_prop?(data, prop.name)
                value = data[prop.name]

                if DocHelpers.form_field?(doc.tagname)
                  bind_to_form_field(prop, prop.name, value, data)
                end

                bind_data_to_doc(prop, value)
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
        value.is_a?(Hash) ? bind_attributes_to_doc(value, doc) : bind_value_to_doc(value, doc)
      end

      def bind_data_to_doc(doc, data)
        data.is_a?(Hash) ? bind_attributes_to_doc(data, doc) : bind_value_to_doc(data, doc)
      end

      def data_has_prop?(data, prop)
        data.include?(prop)
      end

      def bind_value_to_doc(value, doc)
        value = String(value)

        tag = doc.tagname
        return if DocHelpers.tag_without_value?(tag)

        if DocHelpers.self_closing_tag?(tag)
          # don't override value if set
          if !doc.get_attribute(:value) || doc.get_attribute(:value).empty?
            doc.set_attribute(:value, value)
          end
        else
          doc.html = value
        end
      end

      def bind_to_form_field(doc, scope, prop, value, bindable)
        # special binding for checkboxes and radio buttons
        if doc.tagname == 'input' && (doc.get_attribute(:type) == 'checkbox' || doc.get_attribute(:type) == 'radio')
          bind_to_checked_field(doc, value)
          # special binding for selects
        elsif doc.tagname == 'select'
          bind_to_select_field(doc, scope, prop, value, bindable)
        end
      end

      def bind_to_checked_field(doc, value)
        if value == true || (doc.get_attribute(:value) && doc.get_attribute(:value) == value.to_s)
          doc.set_attribute(:checked, 'checked')
        else
          doc.remove_attribute(:checked)
        end

        # coerce to string since booleans are often used and fail when binding to a view
        value.to_s
      end

      def bind_to_select_field(doc, scope, prop, value, bindable)
        create_select_options(doc, scope, prop, value, bindable)
        select_option_with_value(doc, value)
      end

      def set_form_field_name(doc, scope, prop)
        return if doc.get_attribute(:name) && !doc.get_attribute(:name).empty? # don't overwrite the name if already defined
        doc.set_attribute(:name, "#{scope}[#{prop}]")
      end

      # TODO: probably a concern of presenter
      def create_select_options(doc, scope, prop, value, bindable)
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
        doc.clear

        # add generated options
        doc.append(nodes.to_xml)
      end

      def select_option_with_value(doc, value)
        option = doc.option(value: value)
        return if option.nil?

        option.set_attribute(:selected, 'selected')
      end

      def handle_unbound_data(scope, prop)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]") if Pakyow.logger
        throw :unbound
      end

      # TODO: this shouldn't handle content; probably can be simplified
      def bind_attributes_to_doc(attrs, doc)
        attrs.each do |attr, v|
          case attr
          when :content
            v = v.call(doc.html) if v.is_a?(Proc)
            bind_value_to_doc(v, doc)
          when :view
            v.call(View.new(doc: doc))
          else
            attr  = attr.to_s
            attrs = Attributes.new(doc)

            if v.is_a?(Proc)
              attribute = attrs.send(attr)
              ret = v.call(attribute)
              value = ret.respond_to?(:value) ? ret.value : ret

              attrs.send("#{attr}=", value)
            elsif v.nil?
              doc.remove_attribute(attr)
            else
              attrs.send("#{attr}=", v)
            end
          end
        end
      end
    end
  end
end
