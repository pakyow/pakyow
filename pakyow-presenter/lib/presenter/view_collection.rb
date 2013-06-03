module Pakyow
  module Presenter
    class ViewCollection
      include Enumerable
      
      def initialize
        @views = []
      end
      
      def each
        @views.each { |v| yield(v) }
      end
      
      def attributes(*args)
        collection = AttributesCollection.new
        self.each{|v| collection << v.attributes}
        return collection
      end

      alias :attrs :attributes
      
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
      
      def [](i)
        @views[i]
      end

      def length
        @views.length
      end

      def scope(name)
        views = ViewCollection.new
        self.each{|v|
          next unless svs = v.scope(name)
          svs.each{|sv| views << sv}
        }
        
        views
      end

      def prop(name)
        views = ViewCollection.new
        self.each{|v|
          next unless svs = v.prop(name)
          svs.each{|sv| views << sv}
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
      # Yields a view and its matching dataum. Datums are yielded until 
      # no more views or data is available. For the ViewCollection case, this 
      # means the block will be yielded self.length times.
      # 
      # (this is basically Bret's `map` function)
      #
      def for(data, &block)
        data = [data] unless (data.is_a?(Enumerable) && !data.is_a?(Hash))

        self.each_with_index { |v,i|
          break unless datum = data[i]
          block.call(v, datum, i)
        }
      end

      # call-seq:
      #   match(data) => ViewCollection
      #
      # Returns a ViewCollection object that has been manipulated to match the data.
      # For the ViewCollection case, the returned ViewCollection collection will consist n copies
      # of self[data index] || self[-1], where n = data.length.
      #
      def match(data)
        data = [data] unless (data.is_a?(Enumerable) && !data.is_a?(Hash))

        views = ViewCollection.new
        data.each_with_index {|datum,i|
          unless v = self[i]

            # we're out of views, so use the last one
            v = self[-1]
          end

          d_v = v.doc.dup
          v.doc.before(d_v)

          new_v = View.new(d_v)

          # find binding subset (keeps us from refinding)
          new_v.bindings = v.bindings.dup

          views << new_v
        }

        self.remove
        views
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Matches self to data and yields a view/datum pair.
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
        self.for(data) {|view, datum, i|
          view.bind(datum, bindings)
          yield(view, datum, i) if block_given?
        }
      end

      # call-seq:
      #   apply(data)
      #
      # Matches self to data then binds data to the view.
      #
      def apply(data, bindings = {}, &block)
        self.match(data).bind(data, bindings, &block)
      end
    end
  end
end
