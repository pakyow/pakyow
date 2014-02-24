module Pakyow
  module Presenter
    class Presenter
      class << self
        def process(contents, format)
          format = format.to_sym

          unless app = Pakyow.app
            return contents
          end

          unless presenter = app.presenter
            return contents
          end

          unless processor = presenter.processor_store[format]
            Pakyow.logger.warn("No processor defined for extension #{format}") unless format == :html
            return contents
          end

          return processor.call(contents)
        end
      end

      Pakyow::App.before(:init) {
        @presenter = Presenter.new
      }

      Pakyow::App.after(:match) {
        @presenter = Pakyow.app.presenter.dup
        @presenter.prepare_with_context(context)
      }

      Pakyow::App.after(:route) {
        if @presenter.presented?
          @found = true
          @context.response.body = [@presenter.content]
        else
          @found = false unless found?
        end
      }

      Pakyow::App.after(:load) {
        @presenter.load
      }

      Pakyow::App.after(:error) {
        unless config.app.errors_in_browser
          @context.response.body = [@presenter.content] if @presenter.presented?
        end
      }

      attr_accessor :processor_store, :binder, :path, :context, :composer

      def initialize
        setup
      end

      def store(name = nil)
        if name
          @view_stores[name]
        else
          @view_stores[@store]
        end
      end

      def store=(name)
        @store = name

        return unless has_path?
        setup_for_path(@path)
      end

      def load
        load_processors
        load_views
        load_bindings
      end

      def prepare_with_context(context)
        @context = context

        if @context.request.has_route_vars?
          @path = Utils::String.remove_route_vars(@context.request.route_path)
        else
          @path = @context.request.path
        end

        setup
      end

      def presented?
        !view.nil?
      rescue MissingView
        false
      end

      def content
        to_present = view
        view.is_a?(ViewComposer) ? view.composed.to_html : view.to_html
      end

      def view
        view = @composer || @view
        raise MissingView if view.nil?

        view.context = @context

        return view
      end

      def view=(view)
        @view = view
        @view.context = @context

        # setting a view means we no longer use/need the composer
        @composer = nil
      end

      def template=(template)
        raise MissingComposer 'Cannot set template without a composer' if @composer.nil?
        @composer.template = template
      end

      def template
        raise MissingComposer 'Cannot get template without a composer' if @composer.nil?
        @composer.template
      end

      def page=(page)
        raise MissingComposer, 'Cannot set page without a composer' if @composer.nil?
        @composer.page = page
      end

      def page
        raise MissingComposer 'Cannot get page without a composer' if @composer.nil?
        @composer.page
      end

      def container(name)
        raise MissingComposer 'Cannot get container without a composer' if @composer.nil?
        @composer.container(name)
      end

      def partial(name)
        raise MissingComposer 'Cannot get partial without a composer' if @composer.nil?
        @composer.partial(name)
      end

      def path=(path)
        setup_for_path(path, true)
      end

      def compose(opts = {}, &block)
        compose_at(@path, opts, &block)
      end

      def compose_at(path, opts = {}, &block)
        composer = ViewComposer.from_path(store, path, opts, &block)
        return composer unless opts.empty? || block_given?

        @composer = composer
      end

      def has_path?
        !@path.nil?
      end

      protected

      def setup
        @view, @composer = nil
        self.store = :default
      end

      def setup_for_path(path, explicit = false)
        @composer = store.composer(path)
        @path = path
      rescue MissingView => e # catches no view path error
        explicit ? raise(e) : Pakyow.logger.debug(e.message)
      end

      def load_views
        @view_stores = {}

        Config::Presenter.view_stores.each_pair {|name, path|
          @view_stores[name] = ViewStore.new(path, name)
        }
      end

      def load_bindings
        @binder = Binder.instance.reset

        Pakyow::App.bindings.each_pair {|set_name, block|
          @binder.set(set_name, &block)
        }
      end

      def load_processors
        @processor_store = Pakyow::App.processors
      end
    end
  end
end
