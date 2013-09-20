module Pakyow
  module Presenter
    class View
      include DocHelpers

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

      attr_accessor :doc, :scoped_as, :scopes, :related_views
      attr_writer   :bindings

      def dup
        view = self.class.from_doc(@doc.dup)
        view.scoped_as = scoped_as
        return view
      end

      def initialize(contents = '', format = :html)
        @related_views = []

        processed = Presenter.process(contents, format)

        if processed.match(/<html.*>/)
          @doc = Nokogiri::HTML::Document.parse(processed)
        else
          @doc = Nokogiri::HTML.fragment(processed)
        end
      end

      def self.from_doc(doc)
        view = self.new
        view.doc = doc
        return view
      end

      def self.load(path)
        format    = StringUtils.split_at_last_dot(path)[-1]
        contents  = File.read(path)

        return self.new(contents, format)
      end

      def title=(title)
        if @doc
          if o = @doc.css('title').first
            o.inner_html = Nokogiri::HTML::fragment(title)
          else
            if o = @doc.css('head').first
              o.add_child(Nokogiri::HTML::fragment("<title>#{title}</title>"))
            end
          end
        end
      end

      def title
        o = @doc.css('title').first
        o.inner_html if o
      end

      # Allows multiple attributes to be set at once.
      # root_view.find(selector).attributes(:class => my_class, :style => my_style)
      #
      def attributes(attrs = {})
        if attrs.empty?
          return Attributes.new(self.doc)
        else
          self.bind_attributes_to_doc(attrs, doc)
        end
      end

      alias :attrs :attributes

      def remove
        self.doc.remove
        self.refind_significant_nodes
      end

      alias :delete :remove

      def clear
        return if self.doc.blank?
        self.doc.inner_html = ''
        self.refind_significant_nodes
      end

      def text
        self.doc.inner_text
      end

      def text=(text)
        text = text.call(self.text) if text.is_a?(Proc)
        self.doc.content = text.to_s
        self.refind_significant_nodes
      end

      def html
        self.doc.inner_html
      end

      def html=(html)
        html = html.call(self.html) if html.is_a?(Proc)
        self.doc.inner_html = Nokogiri::HTML.fragment(html.to_s)
        self.refind_significant_nodes
      end

      def append(view)
        doc  = view.doc
        num  = doc.children.count
        path = self.path_to(doc)

        self.doc.add_child(view.doc)

        self.update_binding_offset_at_path(num, path)
        self.refind_significant_nodes
      end

      def prepend(view)
        doc  = view.doc
        num  = doc.children.count
        path = self.path_to(doc)

        if first_child = self.doc.children.first
          first_child.add_previous_sibling(doc)
        else
          self.doc = doc
        end

        self.update_binding_offset_at_path(num, path)
        self.refind_significant_nodes
      end

      def after(view)
        doc  = view.doc
        num  = doc.children.count
        path = self.path_to(doc)

        self.doc.after(view.doc)

        self.update_binding_offset_at_path(num, path)
        self.refind_significant_nodes
      end

      def before(view)
        doc  = view.doc
        num  = doc.children.count
        path = self.path_to(doc)

        self.doc.before(view.doc)

        self.update_binding_offset_at_path(num, path)
        self.refind_significant_nodes
      end

      def replace(view)
        doc.replace(view)
      end

      def scope(name)
        name = name.to_sym

        views = ViewCollection.new
        self.bindings.select{|b| b[:scope] == name}.each{|s|
          v = self.view_from_path(s[:path])

          v.bindings = self.update_binding_paths_from_path([s].concat(s[:nested_bindings]), s[:path])
          v.scoped_as = s[:scope]

          views << v
        }

        views
      end

      def prop(name)
        name = name.to_sym

        views = ViewCollection.new

        if binding = self.bindings.select{|binding| binding[:scope] == self.scoped_as}[0]
          binding[:props].each {|prop|
            if prop[:prop] == name
              v = self.view_from_path(prop[:path])

              v.scoped_as = self.scoped_as
              views << v
            end
          }
        end

        views
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      # Unlike previous versions, the context can only be referenced by the
      # block argument. No `context` method will be available.s
      #
      def with
        yield(self)
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
        block.call(self, data[0], 0) if block_given?
      end

      # call-seq:
      #   match(data) => ViewCollection
      #
      # Returns a ViewCollection object that has been manipulated to match the data.
      # For the single View case, the ViewCollection collection will consist n copies
      # of self, where n = data.length.
      #
      def match(data)
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        views = ViewCollection.new
        data.each {|datum|
          d_v = self.doc.dup
          self.doc.before(d_v)

          v = View.from_doc(d_v)
          v.bindings = self.bindings.dup
          v.scoped_as = self.scoped_as

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
      #   bind(data)
      #
      # Binds data across existing scopes.
      #
      def bind(data, bindings = {}, &block)
        scope_info = self.bindings.first

        self.bind_data_to_scope(data, scope_info, bindings)
        yield(self, data, 0) if block_given?
      end

      # call-seq:
      #   apply(data)
      #
      # Matches self to data then binds data to the view.
      #
      def apply(data, bindings = {}, &block)
        views = self.match(data).bind(data, bindings, &block)
      end

      def bindings(refind = false)
        @bindings = (!@bindings || refind) ? self.find_bindings : @bindings
      end

      protected

      # populates the root_view using view_store data by recursively building
      # and substituting in child views named in the structure
      def populate_view(root_view, view_store, view_info)
        root_view.containers.each {|e|
          next unless path = view_info[e[:name]]

          v = self.populate_view(View.new(path, view_store), view_store, view_info)
          self.reset_container(e[:doc])
          self.add_content_to_container(v, e[:doc])
        }
        root_view
      end


      # returns an array of hashes that describe each scope
      def find_bindings(doc = @doc, ignore_root = false)
        bindings = []
        breadth_first(doc) {|o|
          next if o == doc && ignore_root
          next if !scope = o[Config::Presenter.scope_attribute]

          bindings << {
            :scope => scope.to_sym,
            :path => path_to(o),
            :props => find_props(o)
          }

          if o == doc
            # this is the root node, which we need as the first hash in the
            # list of bindings, but we don't want to nest other scopes inside
            # of it in this case
            bindings.last[:nested_bindings] = {}
          else
            bindings.last[:nested_bindings] = find_bindings(o, true)
            # reject so children aren't traversed
            throw :reject
          end
        }

        # find unscoped props
        bindings.unshift({
          :scope => nil,
          :path => [0],
          :props => find_props(doc),
          :nested_bindings => {}
        })

        return bindings
      end

      def find_props(o)
        props = []
        breadth_first(o) {|so|
          # don't go into deeper scopes
          throw :reject if so != o && so[Config::Presenter.scope_attribute]

          next unless prop = so[Config::Presenter.prop_attribute]
          props << {:prop => prop.to_sym, :path => path_to(so)}
        }

        return props
      end

      # returns a new binding set that takes into account the starting point of `path`
      def update_binding_paths_from_path(bindings, path)
        return bindings.collect { |binding|
          dup_binding = binding.dup
          dup_binding[:path] = dup_binding[:path][path.length..-1]

          dup_binding[:props] = dup_binding[:props].collect {|prop|
            dup_prop = prop.dup
            dup_prop[:path] = dup_prop[:path][path.length..-1]
            dup_prop
          }

          dup_binding[:nested_bindings] = update_binding_paths_from_path(dup_binding[:nested_bindings], path)

          dup_binding
        }
      end

      def update_binding_offset_at_path(offset, path)
        # update binding paths for bindings we're iterating on
        self.bindings.each {|binding|
          next unless self.path_within_path?(binding[:path], path)

          binding[:path][0] += offset if binding[:path][0]

          binding[:props].each { |prop|
            prop[:path][0] += offset if prop[:path][0]
          }
        }
      end

      def refind_significant_nodes
        self.bindings(true)

        @related_views.each {|v|
          v.refind_significant_nodes
        }
      end

      def bind_data_to_scope(data, scope_info, bindings = {})
        return unless data

        scope = scope_info[:scope]

        # handle root binding
        if value = Pakyow.app.presenter.binder.value_for_prop(:_root, scope, data, bindings)
          value.is_a?(Hash) ? self.bind_attributes_to_doc(value, self.doc) : self.bind_value_to_doc(value, self.doc)
        end

        scope_info[:props].each {|prop_info|
          catch(:unbound) {
            prop = prop_info[:prop]

            self.handle_unbound_data(scope, prop) unless data_has_prop?(data, prop) || Pakyow.app.presenter.binder.has_prop?(prop, scope, bindings)
            value = Pakyow.app.presenter.binder.value_for_prop(prop, scope, data, bindings)

            doc = doc_from_path(prop_info[:path])

            # handle form field
            self.bind_to_form_field(doc, scope, prop, value, data) if View.form_field?(doc.name)

            # bind attributes or value
            value.is_a?(Hash) ? self.bind_attributes_to_doc(value, doc) : self.bind_value_to_doc(value, doc)
          }
        }
      end

      def data_has_prop?(data, prop)
        (data.is_a?(Hash) && (data.key?(prop) || data.key?(prop.to_s))) || (!data.is_a?(Hash) && data.class.method_defined?(prop))
      end

      def bind_value_to_doc(value, doc)
        return unless value

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
          v.nil? ? doc.remove_attribute(attr) : attrs.send(:"#{attr}=", v)
        end
      end

      def bind_to_form_field(doc, scope, prop, value, bindable)

        # don't overwrite the name if already defined
        if !doc['name'] || doc['name'].empty?
          # set name on form element
          doc['name'] = "#{scope}[#{prop}]"
        end

        # special binding for checkboxes and radio buttons
        if doc.name == 'input' && (doc[:type] == 'checkbox' || doc[:type] == 'radio')
          if value == true || (doc[:value] && doc[:value] == value.to_s)
            doc[:checked] = 'checked'
          else
            doc.delete('checked')
          end

          # coerce to string since booleans are often used
          # and fail when binding to a view
          value = value.to_s
        # special binding for selects
        elsif doc.name == 'select'
          if options = Pakyow.app.presenter.binder.options_for_prop(prop, scope, bindable)
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

          # select appropriate option
          if o = doc.css('option[value="' + value.to_s + '"]').first
            o[:selected] = 'selected'
          end
        end
      end

      def handle_unbound_data(scope, prop)
        Pakyow.logger.warn("Unbound data for #{scope}[#{prop}]")
        throw :unbound
      end
    end
  end
end
