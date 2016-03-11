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

          processed = processor.call(contents)

          # reprocess html content unless we just did that
          return processed if format == :html
          process(processed, :html)
        end
      end

      Pakyow::App.before(:init) {
        next unless Config.presenter.enabled
        @presenter = Presenter.new
        ViewStoreLoader.instance.reset
      }

      Pakyow::App.after(:match) {
        next unless config.presenter.enabled
        @presenter = Pakyow.app.presenter.dup
        @presenter.prepare_with_context(context)
      }

      Pakyow::App.after(:route) {
        next unless config.presenter.enabled
        if config.presenter.require_route && !found?
          @found 
        else
          if @presenter.presented?
            @found = true
            @context.response.body = [@presenter.content]
          else
            @found = false unless found?
          end
        end
      }

      Pakyow::App.after(:load) {
        next unless Config.presenter.enabled
        @presenter.load
      }

      Pakyow::App.after(:error) {
        next unless Config.presenter.enabled || Config.app.errors_in_browser
        @context.response.body = [@presenter.content] if @presenter.presented?
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
          @path = String.remove_route_vars(@context.request.route_path)
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
        to_present.is_a?(ViewComposer) ? to_present.composed.to_html : to_present.to_html
      end

      def view
        @composer || @view || raise(MissingView)
      end

      def view?(path)
        if composer_for_path(path)
          true
        else
          false
        end
      end

      def precompose!
        self.view = @composer.view
      end

      def view=(view)
        @view = view

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
        @composer = ViewComposer.from_path(store, path, opts, &block)
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
        if composer = composer_for_path(path)
          @composer = composer
          @path = path
          return
        end

        e = MissingView.new("No view at path '#{path}'")
        explicit ? raise(e) : Pakyow.logger.info(e.message)
      end

      def load_views
        @view_stores ||= {}

        Pakyow::Config.presenter.view_stores.each_pair { |name, path|
          next unless ViewStoreLoader.instance.modified?(name, path)
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

      def composer_for_path(path)
        @view_stores.each do |name, store|
          begin
            return store.composer(path)
          rescue MissingView
          end
        end

        return nil
      end
    end
  end
end
