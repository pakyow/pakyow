module Pakyow
  module Presenter
    class ViewComposer
      class << self
        def from_path(store, path, opts = {}, &block)
          ViewComposer.new(store, path, opts, &block)
        end
      end

      def initialize(store, path = nil, opts = {}, &block)
        @store = store
        @path = path

        @page = store.page(opts.fetch(:page) {
          path
        })

        @template = store.template(opts.fetch(:template) {
          (@page && @page.info(:template)) || path
        })

        @partials = {}

        begin
          @partials = includes(opts.fetch(:includes))
        rescue
          @partials = store.partials(path) unless path.nil?
        end

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

      def page=(name)
        @page = @store.page(name)
        return self
      end

      def includes(partial_map)
        @partials.merge!(remap_partials(partial_map))
      end

      private

      def remap_partials(partials)
        Hash[partials.map { |name, path|
          [name, Partial.load(@store.expand_partial_path(path))]
        }]
      end

    end
  end
end
