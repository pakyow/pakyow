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
      
      def attributes(*args)
        self.each {|e| e.attributes(*args)}
        return self
      end
      
      def remove
        self.each {|e| e.remove}
      end
      
      alias :delete :remove
      
      # SEE COMMENT IN VIEW
      # def add_class(val)
      #   self.each {|e| e.add_class(val)}
      # end
      
      # SEE COMMENT IN VIEW
      # def remove_class(val)
      #   self.each {|e| e.remove_class(val)}
      # end
      
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
      
      def [](i)
        @views[i]
      end

      def length
        @views.length
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
      # Yields a view and its matching dataum. Datums are yielded until 
      # no more views or data is available. For the Views case, this 
      # means the block will be yielded self.length times.
      # 
      # (this is basically Bret's `map` function)
      #
      def for(data, &block)
        data = [data] unless data.instance_of?(Array)
        self.each_with_index { |v,i|
          break unless datum = data[i]
          block.call(v, datum)
        }
      end

      # call-seq:
      #   mold(data) => Views
      #
      # Returns a Views object that has been manipulated to match the data.
      # For the Views case, the returned Views collection will consist n copies
      # of self[data index] || self[-1], where n = data.length.
      #
      def mold(data)
        data = [data] unless data.instance_of?(Array)

        views = Views.new
        data.each_with_index {|datum,i|
          unless v = self[i]

            # we're out of views, so use the last one
            v = self[-1]
          end

          d_v = v.doc.dup
          v.doc.before(d_v)
          views << View.new(d_v)
        }

        self.remove
        views
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Molds self to match data and yields a view/datum pair using `mold` and `for`.
      #
      def repeat(data, &block)
        self.mold(data).for(data, &block)
      end

      # call-seq:
      #   bind(data)
      #
      # Binds data across existing scopes.
      #
      def bind(data)
        self.for(data) {|view, datum|
          view.bind(datum)
        }
      end

      # call-seq:
      #   apply(data)
      #
      # Molds then binds data to the view using `mold` and `bind`.
      #
      def apply(data)
        self.mold(data).bind(data)
      end
    end
  end
end
