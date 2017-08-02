module Pakyow
  module Presenter
    class ViewSet
      include Enumerable

      attr_reader :views, :name

      def initialize(name: nil)
        @name = name
        @views = []
      end

      def initialize_copy(_)
        super
        @views = map(:dup)
      end

      def each
        @views.each do |view|
          yield(view)
        end
      end

      def find(*names)
        each_with_object(ViewSet.new) { |view, set|
          view.find(*names).each_with_object(set) { |found_view, found_set|
            found_set << found_view
          }
        }
      end

      # call-seq:
      #   with {|view| block}
      #
      # Creates a context in which view manipulations can be performed.
      #
      def with
        yield self; self
      end

      # call-seq:
      #   transform(data) => ViewSet
      #
      # Manipulates the current collection to match the data. The final ViewSet object
      # will consist n copies of self[data index] || self[-1], where n = data.length.
      #
      # Yields each view and object if a block is passed.
      #
      def transform(data)
        working_count = count
        return self if working_count == 0
        data = Array.ensure(data)

        if data.empty?
          remove
        else
          if working_count > data.length
            self[data.length..-1].each do |view|
              delete(view)
            end
          else
            data[working_count..-1].each do
              append(last.dup)
            end
          end
        end

        zip(data).each do |view, object|
          view.transform(object)
          yield view, object if block_given?
        end

        self
      end

      # call-seq:
      #   bind(data)
      #
      # Binds data across existing scopes.
      #
      def bind(data)
        zip(data).each do |view, object|
          view.bind(object)
          yield view, object if block_given?
        end
      end

      # call-seq:
      #   present(data)
      #
      # Matches self to data then binds data to the view.
      #
      def present(data)
        transform(data).bind(data)
      end

      def ==(other)
        @views == other.views
      end

      def remove
        each do |view|
          view.remove
        end

        @views = []
      end

      # TODO: delegator
      def last
        @views.last
      end

      # TODO: delegator
      def [](i)
        @views[i]
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
        self
      end

      def prepend(view)
        first.before(view)
        @views.unshift(view)
        self
      end

      def delete(view)
        view.remove
        @views.delete(view)
        self
      end
    end
  end
end
