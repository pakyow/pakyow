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

        #TODO default should be in config
        def at_path(view_path, view_store = :default)
          v = self.new(Pakyow.app.presenter.view_store(view_store).root_path(view_path), view_store, true)
          v.compile(view_path, view_store)
        end

        #TODO default should be in config
        def root_at_path(view_path, view_store = :default)
          self.new(Pakyow.app.presenter.view_store(view_store).root_path(view_path), view_store, true)
        end

      end

      attr_accessor :doc, :scoped_as, :scopes, :related_views
      attr_writer   :bindings

      def dup
        v = self.class.new(@doc.dup)
        v.scoped_as = self.scoped_as
        v
      end

      def initialize(arg = nil, view_store = :default, is_root_view = false)
        @related_views = []

        if arg.is_a?(Nokogiri::XML::Element) || arg.is_a?(Nokogiri::XML::Document) || arg.is_a?(Nokogiri::HTML::DocumentFragment)
          @doc = arg
        elsif arg.is_a?(Pakyow::Presenter::ViewCollection)
          @doc = arg.first.doc.dup
        elsif arg.is_a?(Pakyow::Presenter::View)
          @doc = arg.doc.dup
        elsif arg.is_a?(String)
          view_path = Pakyow.app.presenter.view_store(view_store).real_path(arg)

          # run parsers
          format = StringUtils.split_at_last_dot(view_path)[1].to_sym
          content = parse_content(File.read(view_path), format)
          
          if is_root_view then
            @doc = Nokogiri::HTML::Document.parse(content)
          else
            @doc = Nokogiri::HTML.fragment(content)
          end
        else
          raise ArgumentError, "No View for you! Come back, one year."
        end
      end

      #TODO default should be in config
      def compile(view_path, view_store = :default)
        return unless view_info = Pakyow.app.presenter.view_store(view_store).view_info(view_path)
        self.populate_view(self, view_store, view_info[:views])
      end

      def parse_content(content, format)
        begin
          Pakyow.app.presenter.processor_store[format].call(content)
        rescue
          Log.warn("No processor defined for extension #{format}") unless format.to_sym == :html
          content
        end
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
      
      def to_html
        @doc.to_html
      end

      alias :to_s :to_html

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
      
      #TODO replace this with a different syntax (?): view.attributes.class.add/remove/has?(:foo)
      # def add_class(val)
      #   self.doc['class'] = "#{self.doc['class']} #{val}".strip
      # end
      
      # def remove_class(val)
      #   self.doc['class'] = self.doc['class'].gsub(val.to_s, '').strip if self.doc['class']
      # end
      
      # def has_class(val)
      #   self.doc['class'].include? val
      # end
      
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
      
      def scope(name)
        name = name.to_sym

        views = ViewCollection.new
        self.bindings.select{|b| b[:scope] == name}.each{|s|
          v = self.view_from_path(s[:path])
          v.bindings = self.bindings_for_child_view(v)
          v.scoped_as = s[:scope]

          views << v
        }

        views
      end
      
      def prop(name)
        name = name.to_sym

        views = ViewCollection.new
        self.bindings.each {|binding|
          binding[:props].each {|prop|
            if prop[:prop] == name
              v = self.view_from_path(prop[:path])
              v.bindings = self.bindings_for_child_view(v)

              views << v
            end
          }
        }

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

          v = View.new(d_v)
          v.bindings = self.bindings.dup
          #TODO set view scope

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

      def container(name)
        matches = self.containers.select{|c| c[:name].to_sym == name.to_sym}

        vs = ViewCollection.new
        matches.each{|m| vs << view_from_path(m[:path])}
        vs
      end

      def containers(refind = false)
        @containers = (!@containers || refind) ? self.find_containers : @containers
      end

      def bindings(refind = false)
        @bindings = (!@bindings || refind) ? self.find_bindings : @bindings
      end

      protected

      def add_content_to_container(content, container)
        content = content.doc unless content.class == String || content.class == Nokogiri::HTML::DocumentFragment || content.class == Nokogiri::XML::Element
        container.add_child(content)
      end

      def reset_container(container)
        container.inner_html = ''
      end


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

      # returns an array of hashes, each with the container name and doc
      def find_containers
        elements = []
        @doc.traverse {|e|
          if name = e.attr(Config::Presenter.container_attribute)
            elements << { :name => name, :doc => e, :path => path_to(e)}
          end
        }
        elements
      end

      # returns an array of hashes that describe each scope
      def find_bindings
        bindings = []
        breadth_first(@doc) {|o|
          next unless scope = o[Config::Presenter.scope_attribute]

          # find props
          props = []
          breadth_first(o) {|so|
            # don't go into deeper scopes
            throw :reject if so != o && so[Config::Presenter.scope_attribute]

            next unless prop = so[Config::Presenter.prop_attribute]
            props << {:prop => prop.to_sym, :path => path_to(so)}
          }

          bindings << {:scope => scope.to_sym, :path => path_to(o), :props => props}
        }

        # determine nestedness (currently unused; leaving in case needed)
        # bindings.each {|b|
        #   nested = []
        #   bindings.each {|b2|
        #     b_doc = doc_from_path(b[:path])
        #     b2_doc = doc_from_path(b2[:path])
        #     nested << b2 if b2_doc.ancestors.include? b_doc
        #   }

        #   b[:nested_scopes] = nested
        # }
        return bindings
      end

      def bindings_for_child_view(child)
        child_path = self.path_to(child.doc)
        child_path_len = child_path.length
        child_bindings = []

        self.bindings.each {|binding|
          # we want paths within the child path
          if self.path_within_path?(binding[:path], child_path)
            # update paths relative to child
            dup = Marshal.load(Marshal.dump(binding))
            
            [dup].concat(dup[:props]).each{|p|
              p[:path] = p[:path][child_path_len..-1]
            }

            child_bindings << dup
          end
        }

        child_bindings
      end

      def breadth_first(doc)
        queue = [doc]
        until queue.empty?
          node = queue.shift
          catch(:reject) {
            yield node
            queue.concat(node.children)
          }
        end
      end

      def path_to(child)
        path = []

        return path if child == @doc

        child.ancestors.each {|a|
          # since ancestors goes all the way to doc root, stop when we get to the level of @doc
          break if a.children.include?(@doc)

          path.unshift(a.children.index(child))
          child = a
        }

        return path
      end

      def path_within_path?(child_path, parent_path)
        parent_path.each_with_index {|pp_step, i|
          return false unless pp_step == child_path[i]
        }

        true
      end

      def doc_from_path(path)
        o = @doc

        # if path is empty we're at self
        return o if path.empty?

        path.each {|i|
          if child = o.children[i]
            o = child
          else
            break
          end
        }

        return o
      end

      def view_from_path(path)
        v = View.new(doc_from_path(path))
        v.related_views << self
        v
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
        self.containers(true)

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
        View.self_closing_tag?(tag) ? doc['value'] = value : doc.inner_html = value
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
        return unless !doc['name'] || doc['name'].empty?
        
        # set name on form element
        doc['name'] = "#{scope}[#{prop}]"

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
        elsif doc.name == 'select' && options = Pakyow.app.presenter.binder.options_for_prop(prop, scope, bindable)
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

          doc.add_child(option_nodes)

          # select appropriate option
          if o = doc.css('option[value="' + value.to_s + '"]').first
            o[:selected] = 'selected'
          end
        end
      end

      def handle_unbound_data(scope, prop)
        Log.warn("Unbound data for #{scope}[#{prop}]") if Config::Base.app.dev_mode == true
        throw :unbound
      end

    end
  end
end
