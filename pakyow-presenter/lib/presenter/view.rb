module Pakyow
  module Presenter
    class View
      class << self
        attr_accessor :binders, :default_view_path, :default_is_root_view

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
          if is_root_view then
            @doc = Nokogiri::HTML::Document.parse(File.read(view_path))
          else
            @doc = Nokogiri::HTML.fragment(File.read(view_path))
          end
        else
          raise ArgumentError, "No View for you! Come back, one year."
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
          @previous_method = :attributes
          return self
        else
          args[0].each_pair { |name, value|
            @previous_method = :attributes
            self.send(name.to_sym, value)            
          }
        end
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
      
      def method_missing(method, *args)
        return unless @previous_method == :attributes
        @previous_method = nil
        
        if method.to_s.include?('=')
          attribute = method.to_s.gsub('=', '')
          value = args[0]

          if value.is_a? Proc
            value = value.call(self.doc[attribute])
          end

          if value.nil?
            self.doc.remove_attribute(attribute)
          else
            self.doc[attribute] = value
          end
        else
          return self.doc[method.to_s]
        end
      end
      
      def class(*args)
        if @previous_method == :attributes
          method_missing(:class, *args)
        else
          super
        end
      end
      
      def id
        if @previous_method == :attributes
          method_missing(:id)
        else
          super
        end
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
        self.find_scopes[name.to_sym]
      end
      
      def prop(name)
        name = name.to_sym

        views = Views.new
        @bindings.each {|binding|
          binding[:props].each {|prop|
            if prop[:prop] == name
              v = View.new(self.from_path(prop[:path]))
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
        self.bind_data_to_scope(data, @bindings.first)
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

      #TODO find subset when creating sub view
      # returns a hash where keys are scope names and values are view collections
      # easy lookup by name
      def find_scopes
        scopes = {}
        breadth_first(@doc) {|o|
          if scope = o[Configuration::Presenter.scope_attribute]
            scope = scope.to_sym
            
            v = View.new(o)
            v.scoped_as = scope

            # find bindings subset (keeps us from refinding for child views)
            v.bindings = self.bindings_for_child_view(v)

            (scopes[scope] ||= Views.new) << v
          end
        }

        return scopes
      end

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
        #     b_doc = from_path(b[:path])
        #     b2_doc = from_path(b2[:path])
        #     nested << b2 if b2_doc.ancestors.include? b_doc
        #   }

        #   b[:nested_scopes] = nested
        # }
        
        return bindings
      end

      def bindings_for_child_view(child)
        @bindings ||= self.find_bindings

        child_path = self.path_to(child.doc)
        @bindings.each {|binding|

          # update paths relative to child
          if binding[:path].eql?(child_path)
            dup = binding.dup

            len = child_path.length
            dup[:path] = dup[:path][len..-1]
            dup[:props].each {|p|
              p[:path] = p[:path][len..-1]
            }
            
            return [dup]
          end
        }
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

      def from_path(path)
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

      def bind_data_to_scope(data, scope)
        return unless data
        
        # create binder instance for this scope
        #TODO pass the binder instance in?
        b_c = View.binders[scope[:scope]] and b_i = b_c.new(data, from_path(scope[:path])) if View.binders

        scope_doc = from_path(scope[:path])
        
        if View.form_tag?(scope_doc.name)
          # set action on scoped form
          scope_doc['action'] = View.action_for_scoped_object(scope, data, scope_doc)
        end
        
        scope[:props].each {|p|
          k = p[:prop]
          v = data[k]

          # get value from binder if available
          #TODO add/use Binder#value_for_prop
          v = b_i.send(k) if b_i && b_i.class.method_defined?(k)

          doc = from_path(p[:path])

          if View.form_field?(doc.name) && (!doc['name'] || doc['name'].empty?)
            # set name on form element
            doc['name'] = "#{scope[:scope]}[#{k}]"

            # special binding for checkboxes and radio buttons
            if doc.name == 'input' && (doc[:type] == 'checkbox' || doc[:type] == 'radio')
              if v == true || (doc[:value] && doc[:value] == v.to_s)
                doc[:checked] = 'checked'
              else
                doc.delete('checked')
              end

              # coerce to string since booleans are often used 
              # and fail when binding to a view
              v = v.to_s
            # special binding for selects
            elsif doc.name == 'select'
              if b_i
                if options = b_i.fetch_options_for(k)
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
              end

              # select appropriate option
              if o = doc.css('option[value="' + v.to_s + '"]').first
                o[:selected] = 'selected'
              end
            end
          end

          if v.is_a? Hash
            v.each do |v_key, v_val|
              if v_val.is_a? Proc
                v_val = v_val.call(doc[v_key.to_s])
              end
              
              if v_val.nil?
                doc.remove_attribute(v_key.to_s)
              elsif v_key == :content
                bind_value_to_doc(v_val, doc)
              else
                doc[v_key.to_s] = v_val.to_s
              end
            end
          else
            bind_value_to_doc(v, doc)
          end
        }
      end

      def bind_value_to_doc(value, doc)
        return unless value

        tag = doc.name
        return if View.tag_without_value?(tag)
        View.self_closing_tag?(tag) ? doc['value'] = value : doc.inner_html = value
      end

    end
  end
end
