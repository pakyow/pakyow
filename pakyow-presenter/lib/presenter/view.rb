module Pakyow
  module Presenter
    class View
      class << self
        attr_accessor :binders, :cache, :default_view_path, :default_is_root_view

        def view_path(dvp, dirv=false)
          self.default_view_path = dvp
          self.default_is_root_view = dirv
        end
      end

      attr_accessor :doc
            
      def initialize(arg=nil, is_root_view=false)
        arg = self.class.default_view_path if arg.nil? && self.class.default_view_path
        is_root_view = self.class.default_is_root_view if arg.nil? && self.class.default_is_root_view
        
        if arg.is_a?(Nokogiri::XML::Element)
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
          # Only load one time if view caching is enabled
          self.class.cache ||= {}
          
          if !self.class.cache.has_key?(view_path) || !Configuration::Base.presenter.view_caching
            if is_root_view then
              self.class.cache[view_path] = Nokogiri::HTML::Document.parse(File.read(view_path))
            else
              self.class.cache[view_path] = Nokogiri::HTML.fragment(File.read(view_path))
            end
          end
          
          @doc = self.class.cache[view_path].dup
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
      
      def add_resource(*args)
        type, resource, options = args
        options ||= {}
        
        content = case type
          when :js  then '<script src="' + Pakyow::Configuration::Presenter.javascripts + '/' + resource.to_s + '.js"></script>'
          when :css then '<link href="' + Pakyow::Configuration::Presenter.stylesheets + '/' + resource.to_s + '.css" rel="stylesheet" media="' + (options[:media] || 'screen, projection') + '" type="text/css">'
        end
        
        if self.doc.fragment? || self.doc.element?
          self.doc.add_previous_sibling(content)
        else
          self.doc.xpath("//head/*[1]").before(content)
        end
      end
      
      def remove_resource(*args)
        type, resource, options = args
        options ||= {}
        
        case type
          when :js then self.doc.css("script[src='#{Pakyow::Configuration::Presenter.javascripts}/#{resource}.js']").remove
          when :css then self.doc.css("link[href='#{Pakyow::Configuration::Presenter.stylesheets}/#{resource}.css']").remove
        end
      end
      
      def find(element)
        group = Views.new
        @doc.css(element).each {|e| group << View.new(e)}
        
        return group
      end
      
      def in_context(&block)
        ViewContext.new(self).instance_eval(&block)
      end
      
      def bind(object, type = nil)
        type = type || StringUtils.underscore(object.class.name)
        
        # This works: .//*
        # Not this:   .//*[@itemprop or @name]
        # WTF!
        #
        @doc.xpath('.//*').each do |o|
          if attribute = o.get_attribute('itemprop')
            selector = attribute
          elsif name = o.get_attribute('name')            
            selector = name
          else
            next
          end
          
          next unless attribute
          
          if selector.include?('[')
            type_len    = type.length
            object_type = selector[0,type_len]
            attribute   = selector[type_len + 1, attribute.length - type_len - 2]
          else
            object_type = nil
            attribute = selector
          end
          
          next if !object_type.nil? && object_type != type          
          
          binding = {
            :element => o,
            :attribute => attribute.to_sym,
            :selector => selector
          }
          
          bind_object_to_binding(object, binding, object_type.nil?)
        end
      end
      
      def repeat_for(objects, &block)
        if o = @doc
          objects.each do |object|
            view = View.new(self)
            view.bind(object)
            ViewContext.new(view).instance_exec(object, &block) if block_given?
            
            o.add_previous_sibling(view.doc)
          end
          
          o.remove
        end
      end

      def reset_container(container)
        if @doc && o = @doc.css("*[id='#{container}']").first
          o.inner_html = ''
        end
      end

      def title=(title)
        if @doc
          if o = @doc.css('title').first
            o.inner_html = title
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
      
      def add_class(val)
        self.doc['class'] = "#{self.doc['class']} #{val}".strip
      end
      
      def remove_class(val)
        self.doc['class'] = self.doc['class'].gsub(val.to_s, '').strip if self.doc['class']
      end
      
      def has_class(val)
        self.doc['class'].include? val
      end
      
      def clear
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
        return unless content
        self.doc.inner_html = content.to_s
      end
      
      alias :html= :content=
      
      def append(content)
        self.doc.inner_html += content.to_s
      end
      
      alias :render :append
      
      def +(value)
        if @previous_method
          append_value(val)
        else
          super
        end
      end
      
      def <<(value)
        if @previous_method
          append_value(val)
        else
          super
        end
      end
      
      def method_missing(method, *args)
        return unless @previous_method == :attributes
        @previous_method = nil
        
        if method.to_s.include?('=')
          attribute = method.to_s.gsub('=', '')
          value = args[0]

          self.doc[attribute] = value
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

      def elements_with_ids
        elements = []
        @doc.traverse {|e|
          if e.has_attribute?("id")
            elements << e
          end
        }
        elements
      end

      protected

      def append_value(value_to_append)
        case @previous_method
        when :content
          append(value_to_append)
        end
        
        @previous_method = nil
      end
      
      def bind_object_to_binding(object, binding, wild = false)
        binder = nil
        
        # fetch value
        if object.is_a? Hash
          value = object[binding[:attribute]]
        else
          if View.binders
            b = View.binders[object.class.to_s.to_sym] and binder = b.new(object, binding[:element])
          end
          
          if binder && binder.class.method_defined?(binding[:attribute])
            value = binder.send(binding[:attribute])
          else
            if wild && !object.class.method_defined?(binding[:attribute])
              return
            elsif Configuration::Base.app.dev_mode == true && !object.class.method_defined?(binding[:attribute])
              Log.warn("Attempting to bind object to #{binding[:html_tag]}#{binding[:selector].gsub('*', '').gsub('\'', '')} but #{object.class.name}##{binding[:attribute]} is not defined.")
              return
            else
              value = object.send(binding[:attribute])
            end
          end
        end
        
        if value.is_a? Hash
          value.each do |k, v|
            if k == :content
              bind_value_to_binding(v, binding, binder)
            else
              binding[:element][k.to_s] = v.to_s
            end
          end
        else
          bind_value_to_binding(value, binding, binder)
        end
      end

      def bind_value_to_binding(value, binding, binder)
        if !self.self_closing_tag?(binding[:element].name)
          if binding[:element].name == 'select'
            if binder
              if options = binder.fetch_options_for(binding[:attribute])
                html = ''
                is_group = false

                options.each do |opt|
                  if opt.is_a?(Array)
                    if opt.first.is_a?(Array)
                      opt.each do |opt2|
                        html << '<option value="' + opt2[0].to_s + '">' + opt2[1].to_s + '</option>'
                      end
                    else
                      html << '<option value="' + opt[0].to_s + '">' + opt[1].to_s + '</option>'
                    end
                  else
                    html << "</optgroup>" if is_group
                    html << '<optgroup label="' + opt.to_s + '">'
                    is_group = true
                  end
                end

                html << "</optgroup>" if is_group

                binding[:element].inner_html = html
              end
            end

            if opt = binding[:element].css('option[value="' + value.to_s + '"]').first
              opt['selected'] = 'selected'
            end
          else
            binding[:element].inner_html = value.to_s
          end
        elsif binding[:element].name == 'input' && binding[:element][:type] == 'checkbox'
          if value == true || binding[:element].attributes['value'].value == value.to_s
            binding[:element]['checked'] = 'checked'
          else
            binding[:element].delete('checked')
          end
        elsif binding[:element].name == 'input' && binding[:element][:type] == 'radio'
          if binding[:element].attributes['value'].value == value.to_s
            binding[:element]['checked'] = 'checked'
          else
            binding[:element].delete('checked')
          end
        else
          binding[:element]['value'] = value.to_s
        end
      end
      
      def self_closing_tag?(tag)
        %w[area base basefont br hr input img link meta].include? tag
      end
      
    end
  end
end
