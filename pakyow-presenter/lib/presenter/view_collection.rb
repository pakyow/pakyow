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

      def attributes(attrs = {})
        collection = AttributesCollection.new
        self.each{|v| collection << v.attributes(attrs)}
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

      def text=(text)
        self.each {|e| e.text = text}
      end

      def html
        self.map { |v| v.html }
      end

      def html=(html)
        self.each {|e| e.html = html}
      end

      def to_html
        self.map { |v| v.to_html }.join('')
      end

      alias :to_s :to_html

      def append(content)
        self.each {|e| e.append(content)}
      end

      alias :render :append

      def prepend(content)
        self.each {|e| e.prepend(content)}
      end

      def <<(val)
        if val.is_a? View
          @views << val
        end
      end

      def concat(views)
        @views.concat(views)
      end

      def [](i)
        view = @views[i]
        return if view.nil?

        return view
      end

      def length
        @views.length
      end

      def scope(name)
        views = ViewCollection.new
        self.each{|v|
          next unless svs = v.scope(name)
          svs.each{ |sv|
            views << sv
          }
        }

        views
      end

      def prop(name)
        views = ViewCollection.new
        self.each{|v|
          next unless svs = v.prop(name)
          svs.each{ |sv|
            views << sv
          }
        }

        views
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
      # Yields a view and its matching dataum. Datums are yielded until
      # no more views or data is available. For the ViewCollection case, this
      # means the block will be yielded self.length times.
      #
      # (this is basically Bret's `map` function)
      #
      def for(data, &block)
        data = Array.ensure(data)

        self.each_with_index { |v,i|
          break unless datum = data[i]

          if block.arity == 1
            v.instance_exec(data[i], &block)
          else
            block.call(v, data[i])
          end
        }
      end

      # call-seq:
      #   for_with_index {|view, datum, i| block}
      #
      # Yields a view, its matching datum, and index. Datums are yielded until
      # no more views or data is available. For the ViewCollection case, this
      # means the block will be yielded self.length times.
      #
      def for_with_index(data, &block)
        i = 0
        self.for(data) do |ctx, datum|
          if block.arity == 2
            ctx.instance_exec(datum, i, &block)
          else
            block.call(ctx, datum, i)
          end

          i += 1
        end
      end

      # call-seq:
      #   match(data) => ViewCollection
      #
      # Returns a ViewCollection object that has been manipulated to match the data.
      # For the ViewCollection case, the returned ViewCollection collection will consist n copies
      # of self[data index] || self[-1], where n = data.length.
      #
      def match(data)
        data = Array.ensure(data)

        views = ViewCollection.new
        data.each_with_index {|datum,i|
          unless v = self[i]

            # we're out of views, so use the last one
            v = self[-1]
          end

          d_v = v.doc.dup
          v.doc.before(d_v)

          new_v = View.from_doc(d_v)

          new_v.scoped_as = v.scoped_as

          views << new_v
        }

        remove
        return views
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
        self.for(data) {|view, datum|
          view.bind(datum, bindings)
          next if block.nil?

          if block.arity == 1
            view.instance_exec(datum, &block)
          else
            block.call(view, datum)
          end
        }
      end

      # call-seq:
      #   bind_with_index(data)
      #
      # Binds data across existing scopes, yielding a view/datum pair with index.
      #
      def bind_with_index(data, bindings = {}, &block)
        i = 0
        self.bind(data) do |ctx, datum|
          if block.arity == 2
            ctx.instance_exec(datum, i, &block)
          else
            block.call(ctx, datum, i)
          end

          i += 1
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
    end
  end
end
