module Pakyow
  module Presenter

    class View
      class << self
        attr_accessor :binders

        def self_closing_tag?(tag)
          %w[area base basefont br hr input img link meta].include? tag
        end

        def form_field?(tag)
          %w[input select textarea button].include? tag
        end

        def tag_without_value?(tag)
          %w[select].include? tag
        end
      end

      attr_accessor :doc, :scoped_as, :context
      attr_writer   :bindings

      def initialize(contents = '', format = :html)
        #TODO make a config option for what doc to use
        @doc = NokogiriDoc.new(Presenter.process(contents, format))
      end

      def initialize_copy(original_view)
        super

        @doc = original_view.doc.dup
        @scoped_as = original_view.scoped_as
        @context = original_view.context
      end

      def self.from_doc(doc)
        view = self.new
        view.doc = doc
        return view
      end

      def self.load(path)
        format    = Utils::String.split_at_last_dot(path)[-1]
        contents  = File.read(path)

        return self.new(contents, format)
      end

      def ==(o)
        self.class == o.class && to_html == o.to_html
      end

			def title=(title)
				@doc.title = title
			end

			#TODO delegate
			def title
				@doc.title
			end

      # Allows multiple attributes to be set at once.
      # root_view.find(selector).attributes(:class => my_class, :style => my_style)
      #
      def attributes(attrs = {})
        if attrs.empty?
          return Attributes.new(@doc)
        else
          bind_attributes_to_doc(attrs, @doc)
        end
      end

      alias :attrs :attributes

      def remove
        @doc.remove
      end

      alias :delete :remove

      def clear
        @doc.clear
      end

      #TODO delegate
      def text
        @doc.text
      end

      def text=(text)
        #TODO make this a helper of some sort
        text = text.call(self.text) if text.is_a?(Proc)
        @doc.text = text
      end

      #TODO delegate
      def html
        @doc.html
      end

      def html=(html)
        #TODO make this a helper of some sort
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
        replacement = case view.class
                      when View then view.doc
                      else view
                      end

        @doc.replace(replacement)
      end

      def scope(name)
        name = name.to_sym

        views = ViewCollection.new
        views.context = @context

        @doc.scope(name).each do |scope_doc|
          view = View.from_doc(scope_doc)
          view.scoped_as = name
          view.context = @context
          views << view
        end

        return views
      end

      def prop(name)
        name = name.to_sym

        views = ViewCollection.new
        views.context = @context

        @doc.prop(scoped_as, name).each do |prop_doc|
          view = View.from_doc(prop_doc)
          view.scoped_as = scoped_as
          view.context = @context
          views << view
        end

        return views
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with(&block)
        if block.arity == 0
          self.instance_exec(&block)
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
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        if block.arity == 1
          self.instance_exec(data[0], &block)
        else
          block.call(self, data[0])
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
				#TODO port this to NokogiriDoc
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        views = ViewCollection.new
        views.context = @context
        data.each {|datum|
          d_v = self.doc.dup
          self.doc.before(d_v)

          v = View.from_doc(d_v)
          v.scoped_as = self.scoped_as
          v.context = @context

          views << v
        }

        self.remove
        views
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Matches self with data and yields a view/datum pair.
      #
      def repeat(data, &block)
        self.match(data).for(data, &block)
      end

      # call-seq:
      #   repeat_with_index(data) {|view, datum, i| block}
      #
      # Matches self with data and yields a view/datum pair with index.
      #
      def repeat_with_index(data, &block)
        self.match(data).for_with_index(data, &block)
      end

      # call-seq:
      #   bind(data)
      #
      # Binds data across existing scopes.
      #
      def bind(data, bindings = {}, &block)
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        scope_info = @doc.bindings.first

        bind_data_to_scope(data[0], scope_info, bindings)

        return if block.nil?

        if block.arity == 1
          instance_exec(data[0], &block)
        else
          block.call(self, data[0])
        end
      end

      # call-seq:
      #   bind_with_index(data)
      #
      # Binds data across existing scopes, yielding a view/datum pair with index.
      #
      def bind_with_index(data, bindings = {}, &block)
        self.bind(data) do |ctx, datum|
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
      def apply(data, bindings = {}, &block)
        self.match(data).bind(data, bindings, &block)
      end

      def includes(partial_map)
        partial_map = partial_map.dup

        # mixin all the partials
        @doc.partials.each do |partial|
          partial[1].replace(partial_map[partial[0]].to_s)
        end

        # now delete them from the map
        @doc.partials.each do |partial|
          partial_map.delete(partial[0])
        end

        # we have more partials
        if partial_map.count > 0
          # initiate another build if content contains partials
          includes(partial_map) if @doc.partials(true).count > 0
        end

        return self
      end

			def to_html
				@doc.to_html
			end

      alias :to_s :to_html

      protected

			#TODO port this to NokogiriDoc
      def partials_in(content)
        partials = []

        content.scan(PARTIAL_REGEX) do |m|
          partials << m[0].to_sym
        end

        return partials
      end

      # populates the root_view using view_store data by recursively building
      # and substituting in child views named in the structure
			#TODO port this to NokogiriDoc
      def populate_view(root_view, view_store, view_info)
        root_view.containers.each {|e|
          next unless path = view_info[e[:name]]

          v = self.populate_view(View.new(path, view_store), view_store, view_info)
          v.context = @context
          self.reset_container(e[:doc])
          self.add_content_to_container(v, e[:doc])
        }
        root_view
      end

      def bind_data_to_scope(data, scope_info, bindings = {})
        return unless data

        scope = scope_info[:scope]

        bind_data_to_root(data, scope, bindings)

        scope_info[:props].each { |prop_info|
          catch(:unbound) {
            prop = prop_info[:prop]

            if data_has_prop?(data, prop) || Pakyow.app.presenter.binder.has_prop?(prop, scope, bindings)
              value = Pakyow.app.presenter.binder.value_for_prop(prop, scope, data, bindings, context)
              doc = prop_info[:doc]

              if View.form_field?(doc.name)
                bind_to_form_field(doc, scope, prop, value, data)
              end

              bind_data_to_doc(doc, value)
            else
              handle_unbound_data(scope, prop)
            end
          }
        }
      end

      def bind_data_to_root(data, scope, bindings)
        return unless value = Pakyow.app.presenter.binder.value_for_prop(:_root, scope, data, bindings, context)
        value.is_a?(Hash) ? self.bind_attributes_to_doc(value, self.doc) : self.bind_value_to_doc(value, self.doc)
      end

      def bind_data_to_doc(doc, data)
        data.is_a?(Hash) ? self.bind_attributes_to_doc(data, doc) : self.bind_value_to_doc(data, doc)
      end

      def data_has_prop?(data, prop)
        (data.is_a?(Hash) && (data.key?(prop) || data.key?(prop.to_s))) || (!data.is_a?(Hash) && data.class.method_defined?(prop))
      end

			#TODO port to NokogiriDoc
      def bind_value_to_doc(value, doc)
        value = String(value)

        tag = doc.name
        return if View.tag_without_value?(tag)

        if View.self_closing_tag?(tag)
          # don't override value if set
          if !doc['value'] || doc['value'].empty?
            doc['value'] = value
          end
        else
          doc.inner_html = value
        end
      end

			#TODO port to NokogiriDoc
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
          end

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

			#TODO port to NokogiriDoc
      def bind_to_form_field(doc, scope, prop, value, bindable)
        set_form_field_name(doc, scope, prop)

        # special binding for checkboxes and radio buttons
        if doc.name == 'input' && (doc[:type] == 'checkbox' || doc[:type] == 'radio')
          bind_to_checked_field(doc, value)
        # special binding for selects
        elsif doc.name == 'select'
          bind_to_select_field(doc, scope, prop, value, bindable)
        end
      end

			#TODO port to NokogiriDoc
      def bind_to_checked_field(doc, value)
        if value == true || (doc[:value] && doc[:value] == value.to_s)
          doc[:checked] = 'checked'
        else
          doc.delete('checked')
        end

        # coerce to string since booleans are often used and fail when binding to a view
        value = value.to_s
      end

      def bind_to_select_field(doc, scope, prop, value, bindable)
        create_select_options(doc, scope, prop, value, bindable)
        select_option_with_value(doc, value)
      end

			#TODO port to NokogiriDoc
      def set_form_field_name(doc, scope, prop)
        return if doc['name'] && !doc['name'].empty? # don't overwrite the name if already defined
        doc['name'] = "#{scope}[#{prop}]"
      end

			#TODO port to NokogiriDoc
      def create_select_options(doc, scope, prop, value, bindable)
        return unless options = Pakyow.app.presenter.binder.options_for_prop(prop, scope, bindable, context)

        option_nodes = Nokogiri::HTML::DocumentFragment.parse ""
        Nokogiri::HTML::Builder.with(option_nodes) do |h|
          until options.length == 0
            catch :optgroup do
              o = options.first

              # an array containing value/content
              if o.is_a?(Array)
                h.option o[1], :value => o[0]
                options.shift
                # likely an object (e.g. string); start a group
              else
                h.optgroup(:label => o) {
                  options.shift

                  options[0..-1].each_with_index { |o2,i2|
                    # starting a new group
                    throw :optgroup if !o2.is_a?(Array)

                    h.option o2[1], :value => o2[0]
                    options.shift
                  }
                }
              end
            end
          end
        end

        # remove existing options
        doc.children.remove

        # add generated options
        doc.add_child(option_nodes)
      end

			#TODO port to NokogiriDoc
      def select_option_with_value(doc, value)
        return unless o = doc.css('option[value="' + value.to_s + '"]').first
        o[:selected] = 'selected'
      end

      def handle_unbound_data(scope, prop)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]")
        throw :unbound
      end
    end
  end
end
