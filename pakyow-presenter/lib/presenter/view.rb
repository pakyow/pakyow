module Pakyow
  module Presenter
    class View
      class << self
        attr_accessor :binders, :default_view_path, :default_is_root_view

        def binder_for_scope(scope, bindable)
          return unless View.binders
          b_c = View.binders[scope] and b_c.new(bindable)
        end

        def view_path(dvp, dirv=false)
          self.default_view_path = dvp
          self.default_is_root_view = dirv
        end

        def self_closing_tag?(tag)
          %w[area base basefont br hr input img link meta].include? tag
        end

        def form_field?(tag)
          %w[input select textarea button].include? tag
        end

        def form_tag?(tag)
          %w[form].include? tag
        end

        def tag_without_value?(tag)
          %w[select].include? tag
        end

        def action_for_scoped_object(scope, o, doc)
          #TODO rewrite to handle restful routes defined for data types, not (just) model names
          unless routes = Pakyow.app.restful_routes[o.class.name.to_sym]
            Log.warn "Attempting to bind object to #{o.class.name.downcase}[action] but could not find restful routes for #{o.class.name}."
            return ''
          end
          
          if id = o[:id]
            doc.add_child('<input type="hidden" name="_method" value="put">')
            
            action = routes[:update].gsub(':id', id.to_s)
            method = "post"
          else
            action = routes[:create]
            method = "post"
          end
          
          doc['action'] = File.join('/', action)
          doc['method'] = method
        end
      end

      attr_accessor :doc, :scoped_as, :scopes, :bindings

      def dup
        v = self.class.new(@doc.dup)
        v.scoped_as = self.scoped_as
        v
      end

      def initialize(arg=nil, is_root_view=false)
        arg = self.class.default_view_path if arg.nil? && self.class.default_view_path
        is_root_view = self.class.default_is_root_view if arg.nil? && self.class.default_is_root_view

        if arg.is_a?(Nokogiri::XML::Element) || arg.is_a?(Nokogiri::XML::Document) || arg.is_a?(Nokogiri::HTML::DocumentFragment)
          @doc = arg
        elsif arg.is_a?(Pakyow::Presenter::Views)
          @doc = arg.first.doc.dup
        elsif arg.is_a?(Pakyow::Presenter::View)
          @doc = arg.doc.dup
        elsif arg.is_a?(String)
          #TODO use File#join
          if arg[0, 1] == '/'
            view_path = "#{Configuration::Presenter.view_dir}#{arg}"
          else
            view_path = "#{Configuration::Presenter.view_dir}/#{arg}"
          end

          # run parsers
          format = view_path.split('.')[-1].to_sym
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

      def parse_content(content, format)
        begin
          Pakyow.app.presenter.parser_store[format].call(content)
        rescue
          Log.warn("No parser defined for extension #{format}") unless format.to_sym == :html
          content
        end
      end

      #TODO rewrite to use data-container
      def add_content_to_container(content, container)
        # TODO This .css call works but the equivalent .xpath call doesn't
        # Need to investigate why since the .css call is internally turned into a .xpath call
        if @doc && o = @doc.css("##{container}").first
          content = content.doc unless content.class == String || content.class == Nokogiri::HTML::DocumentFragment || content.class == Nokogiri::XML::Element
          o.add_child(content)
        end
      end

      #TODO rewrite to use data-container
            # is this ever called, or only the one on LazyView?
      def reset_container(container)
        return unless @doc
        return unless o = @doc.css("*[id='#{container}']").first
        return if o.blank?
        
        o.inner_html = ''
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
      
      #TODO use data-container
      def to_html(container = nil)
        if container
          if o = @doc.css('#' + container.to_s).first
            o.inner_html
          else
            ''
          end
        else
          @doc.to_html
        end
      end

      alias :to_s :to_html

      # Allows multiple attributes to be set at once.
      # root_view.find(selector).attributes(:class => my_class, :style => my_style)
      #
      def attributes(*args)
        if args.empty?
          return Attributes.new(self)
        else
          #TODO mass assign attributes (if we still want to do this)
          #TODO use this instead of (or combine with) bind_attributes_to_doc?
        end

        # if args.empty?
        #   @previous_method = :attributes
        #   return self
        # else
        #   args[0].each_pair { |name, value|
        #     @previous_method = :attributes
        #     self.send(name.to_sym, value)            
        #   }
        # end
      end
      
      def remove
        self.doc.remove
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
      end
      
      def text
        self.doc.inner_text
      end
      
      def content
        self.doc.inner_html
      end
      
      alias :html :content
      
      def content=(content)
        self.doc.inner_html = Nokogiri::HTML.fragment(content.to_s)
      end
      
      alias :html= :content=
      
      def append(view)
        self.doc.add_child(view.doc)
      end
      
      def after(view)
        self.doc.after(view.doc)
      end
      
      def before(view)
        self.doc.before(view.doc)
      end
      
      #TODO replace with a method that finds data-containers
      #  where is this used? needed?
      def elements_with_ids
        elements = []
        @doc.traverse {|e|
          if e.has_attribute?("id")
            elements << e
          end
        }
        elements
      end

      def scope(name)
        name = name.to_sym
        @bindings ||= self.find_bindings

        views = Views.new
        @bindings.select{|b| b[:scope] == name}.each{|s| 
          v = self.view_from_path(s[:path])
          v.bindings = self.bindings_for_child_view(v)
          v.scoped_as = s[:scope]

          views << v
        }

        views
      end
      
      def prop(name)
        name = name.to_sym

        views = Views.new
        @bindings.each {|binding|
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
        data = [data] unless data.instance_of?(Array)
        block.call(self, data[0])
      end

      # call-seq:
      #   match(data) => Views
      #
      # Returns a Views object that has been manipulated to match the data.
      # For the single View case, the Views collection will consist n copies
      # of self, where n = data.length.
      #
      def match(data)
        data = [data] unless data.instance_of?(Array)

        views = Views.new
        data.each {|datum|
          d_v = self.doc.dup
          self.doc.before(d_v)

          v = View.new(d_v)
          v.bindings = self.bindings
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
      def bind(data, &block)
        @bindings ||= self.find_bindings

        scope = @bindings.first
        binder = View.binder_for_scope(scope[:scope], data)

        self.bind_data_to_scope(data, scope, binder)
        yield(self, data) if block_given?
      end

      # call-seq:
      #   apply(data)
      #
      # Matches self to data then binds data to the view.
      #
      def apply(data, &block)
        views = self.match(data).bind(data, &block)
      end

      protected

      # returns an array of hashes that describe each scope
      def find_bindings
        bindings = []
        breadth_first(@doc) {|o|
          next unless scope = o[Configuration::Presenter.scope_attribute]

          # find props
          props = []
          breadth_first(o) {|so|
            # don't go into deeper scopes
            break if so!= o && so[Configuration::Presenter.scope_attribute]

            next unless prop = so[Configuration::Presenter.prop_attribute]
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
        @bindings ||= self.find_bindings
        
        child_path = self.path_to(child.doc)
        child_path_len = child_path.length
        child_bindings = []

        @bindings.each {|binding|
          # we want paths within the child path
          if (child_path - binding[:path]).empty?
            # update paths relative to child
            dup = binding.dup

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
          yield node
          queue.concat(node.children)
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
        View.new(doc_from_path(path))
      end

      def bind_data_to_scope(data, scope, binder = nil)
        return unless data

        # set form action
        self.set_form_action_for_scope_with_data(scope, data) 

        scope[:props].each {|p|
          k = p[:prop]
          v = binder ? binder.value_for_prop(k) : data[k]

          doc = doc_from_path(p[:path])

          # handle form field
          self.bind_to_form_field(doc, scope, k, v, binder) if View.form_field?(doc.name)

          # bind attributes or value
          v.is_a?(Hash) ? self.bind_attributes_to_doc(v, doc) : self.bind_value_to_doc(v, doc)
        }
      end

      def bind_value_to_doc(value, doc)
        return unless value

        tag = doc.name
        return if View.tag_without_value?(tag)
        View.self_closing_tag?(tag) ? doc['value'] = value : doc.inner_html = value
      end

      def bind_attributes_to_doc(attrs, doc)
        attrs.each do |attr, v|
          bind_value_to_doc(v, doc) and next if attr == :content

          attr = attr.to_s
          v = v.call(doc[attr]) if v.is_a?(Proc)
          v.nil? ? doc.remove_attribute(attr) : doc[attr] = v.to_s
        end
      end

      def set_form_action_for_scope_with_data(scope, data)
        doc = self.doc_from_path(scope[:path])
        return if !View.form_tag?(doc.name)

        #TODO rewrite upon refactoring routing (so restful template works right)
        doc['action'] = View.action_for_scoped_object(scope, data, doc)
      end

      def bind_to_form_field(doc, scope, prop, value, binder)
        return unless !doc['name'] || doc['name'].empty?
        
        # set name on form element
        doc['name'] = "#{scope[:scope]}[#{prop}]"

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
        elsif doc.name == 'select' && binder && options = binder.fetch_options_for(prop)
          option_nodes = Nokogiri::HTML::DocumentFragment.parse ""
          Nokogiri::HTML::Builder.with(option_nodes) do |h|
            until options.length == 0
              catch :optgroup do
                options.each_with_index { |o,i|

                  # an array containing value/content
                  if o.is_a?(Array)
                    h.option o[1], :value => o[0]
                    options.delete_at(i)
                  # likely an object (e.g. string); start a group
                  else
                    h.optgroup(:label => o) {
                      options.delete_at(i)

                      options[i..-1].each_with_index { |o2,i2|
                        # starting a new group
                        throw :optgroup if !o2.is_a?(Array)

                        h.option o2[1], :value => o2[0]
                        options.delete_at(i)
                      }
                    }
                  end

                }
              end
            end                    
          end

          doc.add_child(option_nodes)
        end

        # select appropriate option
        if o = doc.css('option[value="' + value.to_s + '"]').first
          o[:selected] = 'selected'
        end
      end

    end
  end
end
