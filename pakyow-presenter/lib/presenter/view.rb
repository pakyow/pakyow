require 'forwardable'

module Pakyow
  module Presenter
    class View
      extend Forwardable

      def_delegators :@doc, :title=, :title, :remove, :clear, :text, :html

      # The object responsible for parsing, manipulating, and rendering
      # the underlying HTML document for the view.
      #
      attr_reader :doc

      # The scope, if any, that the view belongs to.
      #
      attr_accessor :scoped_as

      # Creates a view, running `contents` through any registered view processors for `format`.
      #
      # @param contents [String] the contents of the view
      # @param format [Symbol] the format of contents
      #
      def initialize(contents = '', format: :html)
        @doc = Config.presenter.view_doc_class.new(Presenter.process(contents, format))
      end

      def initialize_copy(original_view)
        super

        @doc = original_view.doc.dup
        @scoped_as = original_view.scoped_as
      end

      # Creates a new view with a soft copy of doc.
      #
      def soft_copy
        copy = View.from_doc(@doc.soft_copy)
        copy.scoped_as = scoped_as
        copy
      end

      # Creates a view from a doc.
      #
      # @see StringDoc
      # @see NokogiriDoc
      #
      def self.from_doc(doc)
        view = new
        view.instance_variable_set(:@doc, doc)
        view
      end

      # Creates a view from a file.
      #
      def self.load(path)
        new(File.read(path), format: File.format(path))
      end

      def ==(other)
        self.class == other.class && @doc == other.doc
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
        text = text.call(self.text) if text.is_a?(Proc)
        @doc.text = text
      end

      def html=(html)
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
        name = name.to_sym
        @doc.scope(name).inject(ViewCollection.new) do |coll, scope|
          view = View.from_doc(scope[:doc])
          view.scoped_as = name
          coll << view
        end
      end

      def prop(name)
        name = name.to_sym
        @doc.prop(scoped_as, name).inject(ViewCollection.new) do |coll, prop|
          view = View.from_doc(prop[:doc])
          view.scoped_as = scoped_as
          coll << view
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
          # dup for later
          original_view = dup if data.length > 1

          # the original view match the first datum
          coll << self

          # create views for the other datums
          data[1..-1].inject(coll) { |coll|
            duped_view = original_view.dup
            after(duped_view)
            coll << duped_view
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
      def bind(data, bindings: {}, ctx: nil, &block)
        datum = Array.ensure(data).first
        bind_data_to_scope(datum, doc.scopes.first, bindings, ctx)
        return if block.nil?

        if block.arity == 1
          instance_exec(datum, &block)
        else
          block.call(self, datum)
        end
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
      def apply(data, bindings: {}, ctx: nil, &block)
        match(data).bind(data, bindings: bindings, ctx: ctx, &block)
      end

      def includes(partial_map)
        partials = @doc.partials
        partial_map = partial_map.dup

        # mixin all the partials
        partials.each do |partial_info|
          partial = partial_map[partial_info[0]]
					next if partial.nil?
          partial_info[1].replace(partial.doc.dup)
        end

        # refind the partials
				partials = @doc.partials

        # if mixed in partials included partials, we want to run includes again with a new map
				if partials.count > 0 && (partial_map.keys - partials.keys).count < partial_map.keys.count
					includes(partial_map)
				end

        self
      end

			def to_html
				@doc.to_html
			end
      alias :to_s :to_html

      private

      def bind_data_to_scope(data, scope_info, bindings, ctx)
        return unless data
        return unless scope_info

        scope = scope_info[:scope]
        bind_data_to_root(data, scope, bindings, ctx)

        scope_info[:props].each do |prop_info|
          catch(:unbound) do
            prop = prop_info[:prop]

            if data_has_prop?(data, prop) || Binder.instance.has_scoped_prop?(scope, prop, bindings)
              value = Binder.instance.value_for_scoped_prop(scope, prop, data, bindings, ctx)
              doc = prop_info[:doc]

              if DocHelpers.form_field?(doc.tagname)
                bind_to_form_field(doc, scope, prop, value, data, ctx)
              end

              bind_data_to_doc(doc, value)
            else
              handle_unbound_data(scope, prop)
            end
          end
        end
      end

      def bind_data_to_root(data, scope, bindings, ctx)
        value = Binder.instance.value_for_scoped_prop(scope, :_root, data, bindings, ctx)
        return if value.nil?

        value.is_a?(Hash) ? bind_attributes_to_doc(value, doc) : bind_value_to_doc(value, doc)
      end

      def bind_data_to_doc(doc, data)
        data.is_a?(Hash) ? bind_attributes_to_doc(data, doc) : bind_value_to_doc(data, doc)
      end

      def data_has_prop?(data, prop)
        (data.is_a?(Hash) && (data.key?(prop) || data.key?(prop.to_s))) || (!data.is_a?(Hash) && data.class.method_defined?(prop))
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

      def bind_to_form_field(doc, scope, prop, value, bindable, ctx)
        set_form_field_name(doc, scope, prop)

        # special binding for checkboxes and radio buttons
        if doc.tagname == 'input' && (doc.get_attribute(:type) == 'checkbox' || doc.get_attribute(:type) == 'radio')
          bind_to_checked_field(doc, value)
          # special binding for selects
        elsif doc.tagname == 'select'
          bind_to_select_field(doc, scope, prop, value, bindable, ctx)
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

      def bind_to_select_field(doc, scope, prop, value, bindable, ctx)
        create_select_options(doc, scope, prop, value, bindable, ctx)
        select_option_with_value(doc, value)
      end

      def set_form_field_name(doc, scope, prop)
        return if doc.get_attribute(:name) && !doc.get_attribute(:name).empty? # don't overwrite the name if already defined
        doc.set_attribute(:name, "#{scope}[#{prop}]")
      end

      def create_select_options(doc, scope, prop, value, bindable, ctx)
        options = Binder.instance.options_for_scoped_prop(scope, prop, bindable, ctx)
        return if options.nil?

        option_nodes = Nokogiri::HTML::DocumentFragment.parse('')
        Nokogiri::HTML::Builder.with(option_nodes) do |h|
          until options.length == 0
            catch :optgroup do
              o = options.first

              # an array containing value/content
              if o.is_a?(Array)
                h.option o[1], value: o[0]
                options.shift
                # likely an object (e.g. string); start a group
              else
                h.optgroup(label: o) {
                  options.shift

                  options[0..-1].each_with_index { |o2,i2|
                    # starting a new group
                    throw :optgroup unless o2.is_a?(Array)

                    h.option o2[1], value: o2[0]
                    options.shift
                  }
                }
              end
            end
          end
        end

        # remove existing options
        doc.clear

        # add generated options
        doc.append(option_nodes.to_html)
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

      def bind_attributes_to_doc(attrs, doc)
        attrs.each do |attr, v|
          case attr
          when :content
            v = v.call(doc.inner_html) if v.is_a?(Proc)
            bind_value_to_doc(v, doc)
            next
          when :view
            v.call(self)
            next
          else
            attr = attr.to_s
            attrs = Attributes.new(doc)
            v = v.call(attrs.send(attr)) if v.is_a?(Proc)

            if v.nil?
              doc.remove_attribute(attr)
            else
              attrs.send(:"#{attr}=", v)
            end
          end
        end
      end
    end
  end
end
