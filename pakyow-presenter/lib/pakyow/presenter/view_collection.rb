module Pakyow
  module Presenter
    # TODO: rename to ViewSet
    class ViewCollection
      include Enumerable

      attr_reader :views, :scoped_as

      def initialize(scoped_as: nil)
        @views = []
        @scoped_as = scoped_as
      end

      def initialize_copy(original_view)
        super

        @views = original_view.views.map(&:dup)
      end

      # TODO: revisit
      def ==(other)
        @views.each_with_index do |view, i|
          return false if view != other.views[i]
        end

        return true
      end

      def each
        @views.each do |view|
          yield(view)
        end
      end

      # TODO: should we manipulate attrs on a collection?
      def attrs(attrs = {})
        inject(AttributesCollection.new) { |coll, view|
          coll << view.attrs(attrs)
        }
      end

      def remove
        each(&:remove)
        @views = []
      end

      def to_a
        @views
      end

      def to_html
        map(&:to_html).join
      end

      alias :to_s :to_html

      def <<(view)
        @views << view; self
      end

      def append(view)
        last.after(view)
        self << view
      end

      # TODO: delegator
      def last
        @views.last
      end

      def delete(view)
        view.remove
        @views.delete(view)
      end

      # TODO: delegator
      def concat(views)
        @views.concat(views)
      end

      # TODO: delegator
      def [](i)
        @views[i]
      end

      # TODO: delegator
      def length
        @views.length
      end

      # TODO: replace with `find`
      def scope(name)
        collection = inject(ViewCollection.new(name)) { |coll, view|
          scopes = view.scope(name)
          next if scopes.nil?

          scopes.inject(coll) { |set, scoped_view|
            set << scoped_view
          }
        }

        # if collection.versioned?
        #   ViewVersion.new(collection.views)
        # else
          collection
        # end
      end

      # TODO: replace with `find`
      def prop(name)
        inject(ViewCollection.new) { |coll, view|
          scopes = view.prop(name)
          next if scopes.nil?

          scopes.inject(coll) { |set, scoped_view|
            set << scoped_view
          }
        }
      end

      # def versioned?
      #   each do |view|
      #     return true if view.versioned?
      #   end
      #
      #   false
      # end

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

        self
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
        return self if length == 0
        data = Array.ensure(data)

        # an empty set always means an empty view
        if data.empty?
          remove
        else
          if length > data.length
            self[data.length..-1].each do |view|
              delete(view)
            end
          else
            data[length..-1].each do
              append(last.dup)
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
      def bind(data, &block)
        self.for(data) do |view, datum|
          view.bind(datum)
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
      def apply(data, &block)
        match(data).bind(data, &block)
      end
    end
  end
end
