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
      end

      attr_accessor :doc, :scoped_as, :scopes

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

      def add_content_to_container(content, container)
        # TODO This .css call works but the equivalent .xpath call doesn't
        # Need to investigate why since the .css call is internally turned into a .xpath call
        if @doc && o = @doc.css("##{container}").first
          content = content.doc unless content.class == String || content.class == Nokogiri::HTML::DocumentFragment || content.class == Nokogiri::XML::Element
          o.add_child(content)
        end
      end

      #TODO consider removing (never used since this should happen on front-end)
      # def add_resource(*args)
      #   type, resource, options = args
      #   options ||= {}
        
      #   content = case type
      #     when :js  then '<script src="' + Pakyow::Configuration::Presenter.javascripts + '/' + resource.to_s + '.js"></script>'
      #     when :css then '<link href="' + Pakyow::Configuration::Presenter.stylesheets + '/' + resource.to_s + '.css" rel="stylesheet" media="' + (options[:media] || 'screen, projection') + '" type="text/css">'
      #   end
        
      #   if self.doc.fragment? || self.doc.element?
      #     self.doc.add_previous_sibling(content)
      #   else
      #     self.doc.xpath("//head/*[1]").before(content)
      #   end
      # end
      
      #TODO consider removing (never used since this should happen on front-end)
      # def remove_resource(*args)
      #   type, resource, options = args
      #   options ||= {}
        
      #   case type
      #     when :js then self.doc.css("script[src='#{Pakyow::Configuration::Presenter.javascripts}/#{resource}.js']").remove
      #     when :css then self.doc.css("link[href='#{Pakyow::Configuration::Presenter.stylesheets}/#{resource}.css']").remove
      #   end
      # end
      
      # def find(element)
      #   group = Views.new
      #   @doc.css(element).each {|e| group << View.new(e)}
        
      #   return group
      # end
      
      # def in_context(&block)
      #   ViewContext.new(self).instance_exec(self, &block)
      # end
      
      # def bind(object, opts = {})
      #   bind_as = opts[:to] ? opts[:to].to_s : StringUtils.underscore(object.class.name.split('::').last)
        
      #   @doc.traverse do |o|
      #     if attribute = o.get_attribute('itemprop')
      #       selector = attribute
      #     elsif attribute = o.get_attribute('name')
      #       selector = attribute
      #     else
      #       next
      #     end
          
      #     next unless attribute
          
      #     type_len    = bind_as.length
      #     next if selector[0, type_len + 1] != "#{bind_as}["
          
      #     attribute   = selector[type_len + 1, attribute.length - type_len - 2]
          
      #     binding = {
      #       :element => o,
      #       :attribute => attribute.to_sym,
      #       :selector => selector
      #     }
          
      #     bind_object_to_binding(object, binding, bind_as)
      #   end
      # end
      
      # def repeat_for(objects, opts = {}, &block)
      #   if o = @doc
      #     objects.each do |object|
      #       view = View.new(self)
      #       view.bind(object, opts)
      #       ViewContext.new(view).instance_exec(object, view, &block) if block_given?
            
      #       o.add_previous_sibling(view.doc)
      #     end
          
      #     o.remove
      #   end
      # end

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
      
      alias :render :append
     
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

      # binds a single object to view (little bind)
      #TODO make this work with more than hashes
      def bind(datum)
        self.find_bindings.each { |binding|
          if (b_c = View.binders[self.scoped_as] and b_i = b_c.new(datum, binding[:doc])) && b_i.class.method_defined?(binding[:prop]) #TODO unit test
            value = b_i.send(binding[:prop])
          else
            value = datum[binding[:prop]]
          end
          
          bind_value_to_doc(value, binding[:doc])
        }
      end

      #TODO checkboxes
      #TODO radio buttons
      #TODO select options
      def bind_value_to_doc(value, doc)
        if View.self_closing_tag?(doc.name) #TODO unit test
          doc['value'] = value
        else
          doc.content = value
        end
      end

      # repeat a view n times
      def repeat(data, &block)
        data.each { |d|
          block.call(self.dup, d)
        }
      end

      # molds a view to match a data structure (big bind)
      def mold(structure)

      end

      def with(&block)
        block.call(self)
      end

      protected

      def find_scopes
        arr = {}
        @doc.traverse {|o|
          if scope_name = o['data-scope']
            scope_name = scope_name.to_sym

            v = View.new(o)
            v.scoped_as = scope_name

            (arr[scope_name] ||= Views.new) << v
          end
        }

        arr
      end

      def find_bindings
        bindings = []
        @doc.traverse {|o|
          # don't go into a deeper scope
          next if o.get_attribute('data-scope')

          if prop = o.get_attribute('data-prop')
            bindings << { :doc => o, :prop => prop.to_sym }
          end

          #TODO handle form fields
        }

        bindings
      end

      # def bind_object_to_binding(object, binding, bind_as)
      #   binder = nil
        
      #   if View.binders
      #     b = View.binders[bind_as.to_sym] and binder = b.new(object, binding[:element])
      #   end
        
      #   if binder && binder.class.method_defined?(binding[:attribute])
      #     value = binder.send(binding[:attribute])
      #   else
      #     if object.is_a? Hash
      #       value = object[binding[:attribute]]
      #     else
      #       if Configuration::Base.app.dev_mode == true && !object.class.method_defined?(binding[:attribute])
      #         Log.warn("Attempting to bind object to #{binding[:html_tag]}#{binding[:selector].gsub('*', '').gsub('\'', '')} but #{object.class.name}##{binding[:attribute]} is not defined.")
      #         return
      #       else
      #         value = object.send(binding[:attribute])
      #       end
      #     end
      #   end
        
      #   if value.is_a? Hash
      #     value.each do |k, v|
      #       if v.is_a? Proc
      #         v = v.call(binding[:element][k.to_s])
      #       end
            
      #       if v.nil?
      #         binding[:element].remove_attribute(k.to_s)
      #       elsif k == :content
      #         bind_value_to_binding(v, binding, binder)
      #       else
      #         binding[:element][k.to_s] = v.to_s
      #       end
      #     end
      #   else
      #     bind_value_to_binding(value, binding, binder)
      #   end
      # end

      # def bind_value_to_binding(value, binding, binder)
      #   if !self.self_closing_tag?(binding[:element].name)
      #     if binding[:element].name == 'select'
      #       if binder
      #         if options = binder.fetch_options_for(binding[:attribute])
      #           html = ''
      #           is_group = false

      #           options.each do |opt|
      #             if opt.is_a?(Array)
      #               if opt.first.is_a?(Array)
      #                 opt.each do |opt2|
      #                   html << '<option value="' + opt2[0].to_s + '">' + opt2[1].to_s + '</option>'
      #                 end
      #               else
      #                 html << '<option value="' + opt[0].to_s + '">' + opt[1].to_s + '</option>'
      #               end
      #             else
      #               html << "</optgroup>" if is_group
      #               html << '<optgroup label="' + opt.to_s + '">'
      #               is_group = true
      #             end
      #           end

      #           html << "</optgroup>" if is_group

      #           binding[:element].inner_html = Nokogiri::HTML::fragment(html)
      #         end
      #       end

      #       if opt = binding[:element].css('option[value="' + value.to_s + '"]').first
      #         opt['selected'] = 'selected'
      #       end
      #     else
      #       binding[:element].inner_html = Nokogiri::HTML.fragment(value.to_s)
      #     end
      #   elsif binding[:element].name == 'input' && binding[:element][:type] == 'checkbox'
      #     if value == true || (binding[:element].attributes['value'] && binding[:element].attributes['value'].value == value.to_s)
      #       binding[:element]['checked'] = 'checked'
      #     else
      #       binding[:element].delete('checked')
      #     end
      #   elsif binding[:element].name == 'input' && binding[:element][:type] == 'radio'
      #     if binding[:element].attributes['value'].value == value.to_s
      #       binding[:element]['checked'] = 'checked'
      #     else
      #       binding[:element].delete('checked')
      #     end
      #   else
      #     binding[:element]['value'] = value.to_s
      #   end
      # end
      
    end
  end
end
