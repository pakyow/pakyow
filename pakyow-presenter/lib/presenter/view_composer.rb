module Pakyow
  module Presenter
    class ViewComposer
      class << self
        def from_path(store, path, opts = {}, &block)
          ViewComposer.new(store, path, opts, &block)
        end
      end

      attr_accessor :context
      attr_reader :store, :path, :page, :partials

      def initialize(store, path = nil, opts = {}, &block)
        @store = store
        @path = path

        self.page = opts.fetch(:page) {
          path
        }

        self.template = opts.fetch(:template) {
          (@page.is_a?(Page) && @page.info(:template)) || path
        }

        @partials = {}

        begin
          @partials = includes(opts.fetch(:includes))
        rescue
          @partials = store.partials(path) unless path.nil?
        end

        instance_exec(&block) if block_given?
      end

      def precompose!
        @view = build_view
        clean!
      end

      def view
        return @view unless dirty?
        build_view
      end

      def template(template = nil)
        return @template if template.nil?

        self.template = template
        return self
      end

      def template=(template)
        unless template.is_a?(Template)
          # get template by name
          template = @store.template(template)
        end

        @template = template
        dirty!

        return self
      end

      def page=(page)
        unless page.is_a?(Page)
          # get page by name
          page = @store.page(page)
        end

        @page = page
        dirty!

        return self
      end

      def includes(partial_map)
        dirty!

        @partials.merge!(remap_partials(partial_map))
      end

      def partials=(partial_map)
        dirty!
        @partials.merge!(remap_partials(partial_map))
      end

      def partial(name)
        @partials[name]
      end

      def dirty?
        @dirty
      end

      def dup
        composer = self.class.allocate

        %w[store path page template partials view dirty].each do |ivar|
          value = self.instance_variable_get("@#{ivar}")
          value = value.dup unless value.is_a?(FalseClass) || value.is_a?(TrueClass)
          composer.instance_variable_set("@#{ivar}", value)
        end

        return composer
      end

      private

      def clean!
        @dirty = false
      end

      def dirty!
        @dirty = true
      end

      def build_view
        raise MissingTemplate, "No template provided to view composer" if @template.nil?
        raise MissingPage, "No page provided to view composer" if @page.nil?

        view = @template.build(@page).includes(@partials)

        # set title
        title = @page.info(:title)
        view.title = title unless title.nil?

        return view
      end

      def remap_partials(partials)
        Hash[partials.map { |name, partial_or_path|
          if partial_or_path.is_a?(Partial)
            partial = partial_or_path
          else
            partial = Partial.load(@store.expand_partial_path(path))
          end

          [name, partial]
        }]
      end

    end
  end
end
