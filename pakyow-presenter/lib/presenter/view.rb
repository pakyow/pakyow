module Pakyow
  module Presenter

    class View
      class << self
        attr_accessor :binders

        def self_closing_tag?(tag)
          %w[area base basefont br hr input img link meta].include? tag
        end

        def form_field?(tag)
          %w[input select textarea button].include? tag
        end

        def tag_without_value?(tag)
          %w[select].include? tag
        end
      end

      attr_accessor :doc, :scoped_as
      attr_writer   :bindings

      def initialize(contents = '', format = :html)
        #TODO make a config option for what doc to use
        @doc = NokogiriDoc.new(Presenter.process(contents, format))
      end

      def initialize_copy(original_view)
        super

        @doc = original_view.doc.dup
        @scoped_as = original_view.scoped_as
      end

      def self.from_doc(doc)
        view = self.new
        view.doc = doc
        return view
      end

      def self.load(path)
        format    = Utils::String.split_at_last_dot(path)[-1]
        contents  = File.read(path)

        return self.new(contents, format)
      end

      def ==(o)
        self.class == o.class && to_html == o.to_html
      end

			def title=(title)
				@doc.title = title
			end

			#TODO delegate
			def title
				@doc.title
			end

      # Allows multiple attributes to be set at once.
      # root_view.find(selector).attributes(:class => my_class, :style => my_style)
      #
      def attributes(attrs = {})
        if attrs.empty?
          return Attributes.new(@doc)
        else
          Binder.instance.bind_attributes_to_doc(attrs, @doc)
        end
      end

      alias :attrs :attributes

      def remove
        @doc.remove
      end

      alias :delete :remove

      def clear
        @doc.clear
      end

      #TODO delegate
      def text
        @doc.text
      end

      def text=(text)
        #TODO make this a helper of some sort
        text = text.call(self.text) if text.is_a?(Proc)
        @doc.text = text
      end

      #TODO delegate
      def html
        @doc.html
      end

      def html=(html)
        #TODO make this a helper of some sort
        html = html.call(self.html) if html.is_a?(Proc)
        @doc.html = html
      end

      def append(view)
        @doc.append(view.doc)
      end

      def prepend(view)
        @doc.prepend(view.doc)
      end

      def after(view)
        @doc.after(view.doc)
      end

      def before(view)
        @doc.before(view.doc)
      end

      def replace(view)
        replacement = case view.class
                      when View then view.doc
                      else view
                      end

        @doc.replace(replacement)
      end

      def scope(name)
        name = name.to_sym

        views = ViewCollection.new

        @doc.scope(name).each do |scope_doc|
          view = View.from_doc(scope_doc)
          view.scoped_as = name
          views << view
        end

        return views
      end

      def prop(name)
        name = name.to_sym

        views = ViewCollection.new

        @doc.prop(scoped_as, name).each do |prop_doc|
          view = View.from_doc(prop_doc)
          view.scoped_as = scoped_as
          views << view
        end

        return views
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
      # Yields a view and its matching dataum. This is driven by the view,
      # meaning datums are yielded until no more views are available. For
      # the single View case, only one view/datum pair is yielded.
      #
      # (this is basically Bret's `map` function)
      #
      def for(data, &block)
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        if block.arity == 1
          self.instance_exec(data[0], &block)
        else
          block.call(self, data[0])
        end
      end

      # call-seq:
      #   for_with_index {|view, datum, i| block}
      #
      # Yields a view, its matching dataum, and the index. See #for.
      #
      def for_with_index(data, &block)
       self.for(data) do |ctx, datum|
          if block.arity == 2
            ctx.instance_exec(datum, 0, &block)
          else
            block.call(ctx, datum, 0)
          end
        end
      end

      # call-seq:
      #   match(data) => ViewCollection
      #
      # Returns a ViewCollection object that has been manipulated to match the data.
      # For the single View case, the ViewCollection collection will consist n copies
      # of self, where n = data.length.
      #
      def match(data)
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))

        views = ViewCollection.new
        data.each {|datum|
          d_v = @doc.dup
          @doc.before(d_v)

          v = View.from_doc(d_v)
          v.scoped_as = @scoped_as

          views << v
        }

        remove
        views
      end

      # call-seq:
      #   repeat(data) {|view, datum| block}
      #
      # Matches self with data and yields a view/datum pair.
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
        #TODO move to a helper or something
        data = data.to_a if data.is_a?(Enumerator)
        data = [data] if (!data.is_a?(Enumerable) || data.is_a?(Hash))
        Binder.instance.bind(data[0], self, bindings, ctx)

        #TODO move to a helper or something
        # `exec_or_call`
        return if block.nil?
        if block.arity == 1
          instance_exec(data[0], &block)
        else
          block.call(self, data[0])
        end
      end

      # call-seq:
      #   bind_with_index(data)
      #
      # Binds data across existing scopes, yielding a view/datum pair with index.
      #
      def bind_with_index(*a, **k, &block)
        bind(*a, **k) do |ctx, datum|
          #TODO move to a helper or something
          if block.arity == 2
            ctx.instance_exec(datum, 0, &block)
          else
            block.call(ctx, datum, 0)
          end
        end
      end

      # call-seq:
      #   apply(data)
      #
      # Matches self to data then binds data to the view.
      #
      def apply(data, bindings = {}, &block)
        match(data).bind(data, bindings, &block)
      end

      def includes(partial_map)
        partial_map = partial_map.dup

        # mixin all the partials
        @doc.partials.each do |partial|
          partial[1].replace(partial_map[partial[0]].to_s)
        end

        # now delete them from the map
        @doc.partials.each do |partial|
          partial_map.delete(partial[0])
        end

        # we have more partials
        if partial_map.count > 0
          # initiate another build if content contains partials
          includes(partial_map) if @doc.partials(true).count > 0
        end

        return self
      end

			def to_html
				@doc.to_html
			end
      alias :to_s :to_html
    end
  end
end

