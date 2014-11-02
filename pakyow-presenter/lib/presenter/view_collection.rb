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

      def attrs(attrs = {})
        inject(AttributesCollection.new) { |coll, view|
          coll << view.attrs(attrs)
        }
      end

      def remove
        each {|e| e.remove}
      end

      def clear
        each {|e| e.clear}
      end

      def text
        map { |v| v.text }
      end

      def text=(text)
        each {|e| e.text = text}
      end

      def html
        map { |v| v.html }
      end

      def html=(html)
        each {|e| e.html = html}
      end

      def to_html
        map { |v| v.to_html }.join('')
      end

      alias :to_s :to_html

      def append(content)
        each do |view|
          view.append(content)
        end
      end

      def prepend(content)
        each do |view|
          view.prepend(content)
        end
      end

      def <<(val)
        if val.is_a? View
          @views << val
        end

        self
      end

      def concat(views)
        @views.concat(views)
      end

      def [](i)
        @views[i]
      end

      def length
        @views.length
      end

      def scope(name)
        inject(ViewCollection.new) { |coll, view|
          scopes = view.scope(name)
          next if scopes.nil?

          scopes.inject(coll) { |coll, scoped_view|
            coll << scoped_view
          }
        }
      end

      def prop(name)
        inject(ViewCollection.new) { |coll, view|
          scopes = view.prop(name)
          next if scopes.nil?

          scopes.inject(coll) { |coll, scoped_view|
            coll << scoped_view
          }
        }
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with(&block)
        if block.arity == 0
          instance_exec(&block)
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
        each_with_index do |view, i|
          datum = data[i]
          break if datum.nil?

          if block.arity == 1
            view.instance_exec(data[i], &block)
          else
            block.call(view, data[i])
          end
        end
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
      # Manipulates the current collection to match the data. The final ViewCollection object
      # will consist n copies of self[data index] || self[-1], where n = data.length.
      #
      def match(data)
        data = Array.ensure(data)

        # an empty set always means an empty view
        if data.empty?
          remove
        else
          original_view = self[-1].soft_copy if data.length > length

          if length > data.length
            self[data.length..-1].each do |view|
              view.remove
            end
          else
            data[length..-1].each do
              duped_view = original_view.soft_copy
              self[-1].after(duped_view)
              self << duped_view
            end
          end
        end

        self
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Matches self to data and yields a view/datum pair.
      #
      def repeat(data, &block)
        match(data).for(data, &block)
      end

      # call-seq:
      #   repeat_with_index(data) {|view, datum, i| block}
      #
      # Matches self with data and yields a view/datum pair with index.
      #
      def repeat_with_index(data, &block)
        match(data).for_with_index(data, &block)
      end

      # call-seq:
      #   bind(data)
      #
      # Binds data across existing scopes.
      #
      def bind(data, bindings: {}, ctx: nil, &block)
        self.for(data) do |view, datum|
          view.bind(datum, bindings: bindings, ctx: ctx)
          next if block.nil?

          if block.arity == 1
            view.instance_exec(datum, &block)
          else
            block.call(view, datum)
          end
        end
      end

      # call-seq:
      #   bind_with_index(data)
      #
      # Binds data across existing scopes, yielding a view/datum pair with index.
      #
      def bind_with_index(*a, **k, &block)
        i = 0
        bind(*a, **k) do |ctx, datum|
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
      def apply(data, bindings: {}, ctx: nil, &block)
        match(data).bind(data, bindings: bindings, ctx: ctx, &block)
      end
    end
  end
end
