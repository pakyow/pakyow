module Pakyow
  module Presenter
    class ViewComposer
      def initialize(store, context = nil, &block)
        @store = store
        @context = context

        set_defaults
        instance_exec(&block) if block_given?
      end

      def view
        raise MissingTemplate, "No template provided to view composer" if @template.nil?
        raise MissingPage, "No page provided to view composer" if @page.nil?

        @template.build(@page).includes(@partials)
      end

      def template(name)
        @template = @store.template(name)
        return self
      end

      def at(path)
        @page = @store.page(path)
        template(@page.info(:template))
        @partials = @store.partials(path)
        return self
      end

      def includes(partial_map)
        @partials.merge!(remap_partials(partial_map))
      end

      private

      def set_defaults
        template(:pakyow)
        @partials = {}

        return if @context.nil?

        at(@context.request.path)
      end

      def remap_partials(partials)
        Hash[partials.map { |name, path|
          [name, Partial.load(@store.expand_partial_path(path))]
        }]
      end

    end
  end
end
