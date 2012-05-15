module Pakyow
  module Presenter
    class Views
      include Enumerable
      
      def initialize
        @views = []
      end
      
      def each
        @views.each { |v| yield(v) }
      end
      
      def in_context(&block)
        ViewContext.new(self).instance_exec(self, &block)
      end
      
      def attributes(*args)
        self.each {|e| e.attributes(*args)}
        return self
      end
      
      def remove
        self.each {|e| e.remove}
      end
      
      alias :delete :remove
      
      def add_class(val)
        self.each {|e| e.add_class(val)}
      end
      
      def remove_class(val)
        self.each {|e| e.remove_class(val)}
      end
      
      def clear
        self.each {|e| e.clear}
      end
      
      def text
        self.map { |v| v.text }
      end
      
      def content
        self.map { |v| v.content }
      end
      
      alias :html :content
      
      def content=(content)
        self.each {|e| e.content = content}
      end
      
      alias :html= :content=

      def to_html
        self.map { |v| v.to_html }.join('')
      end

      alias :to_s :to_html

      def append(content)
        self.each {|e| e.append(content)}
      end
      
      alias :render :append
     
      def <<(val)
        if val.is_a? View
          @views << val
        end
      end
      
      def method_missing(method, *args)
        if method.to_s.include?('=')
          self.each {|e| e.send(method, *args)}
        else
          self.map {|e| e.send(method, *args)}
        end
      end
      
      def class(*args)
        method_missing(:class, *args)
      end
      
      def id
        method_missing(:id)
      end
      
      # def repeat_for(objects, opts = {}, &block)
      #   first_found = self.first
        
      #   # Remove other matches
      #   self.drop(1).each {|found| found.remove}
        
      #   # Repeat for first match
      #   first_found.repeat_for(objects, opts, &block)
      # end
      
      def bind(data)
        data = data.is_a?(Array) ? data : [data]
        self.each_with_index {|e,i| e.bind(data[i])}
      end
      
      # def find(element, &block)
      #   views = Views.new
      #   self.each {|e| e.find(element, &block).each { |v| views << v }}
      #   views
      # end

      def [](i)
        @views[i]
      end

      def length
        @views.length
      end

      def with(&block)
        block.call(self)
      end



      # NOTE not entirely right but here to give the idea
      # Duping the same view each time is correct but I think this adds each dup after the
      # original and not after the last dup. Need to remove the original, too.
      # Note 2: map may not be a good name in the end
      def map(ds, &b)
        ds = [ds] unless ds instance_of?(Array)
        ds.each { |d|
          sibs = @views.collect { |v| v.doc.after(v.doc.dup) }
          yield *sibs, d if block_given?
        }
      end


      #TODO implement scope, with, etc
    end
  end
end
