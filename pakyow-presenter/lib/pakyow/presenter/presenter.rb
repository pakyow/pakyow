module Pakyow
  class App
    class << self
      RESOURCE_ACTIONS[:presenter] = proc do |app, name, _, _|
        app.bindings(name) { scope(name) { restful(name) } }
      end

      # TODO: definable
      def bindings(set_name = :main, &block)
        if set_name && block
          bindings[set_name] = block
        else
          @bindings ||= {}
        end
      end

      # TODO: definable
      def processor(*args, &block)
        args.each {|format|
          processors[format] = block
        }
      end

      # TODO: definable
      def processors
        @processors ||= {}
      end
    end

    # Convenience method for defining bindings on an app instance.
    #
    # TODO: definable
    def bindings(set_name = :main, &block)
      self.class.bindings(set_name, &block)
    end

    def processors
      self.class.processors
    end

    # TODO: do we need this?
    def presenter
      @presenter
    end
  end
end

module Pakyow
  module Presenter
    def self.included(base)
      load_presenter_into(base)
    end

    def self.load_presenter_into(app_class)
      app_class.router :__presenter do
        handle 404 do
          presenter_handle_error(404)
        end

        handle 500 do
          presenter_handle_error(500)
        end
      end

      app_class.before :initialize do
        @presenter = Presenter.new(self)
        ViewStoreLoader.instance.reset
      end

      app_class.after :load do
        @presenter.load
      end
    end

    protected

    def presenter_handle_error(code)
      return if !config.app.errors_in_browser || req.format != :html
      response.body = [content_for_code(code)]
    end

    def content_for_code(code)
      content = ERB.new(File.read(path_for_code(code))).result(binding)
      page = Presenter::Page.new(:presenter, content, "/")
      composer = presenter.compose_at("/", page: page)
      composer.to_html
    end

    def path_for_code(code)
      File.join(
        File.expand_path("../../../", __FILE__),
        "views",
        "errors",
        code.to_s + ".erb"
      )
    end

    class Presenter
      Controller.before :route do
        @presenter = app.presenter.dup
        @presenter.prepare_with_context(self)
      end

      Controller.after :route do
        if app.config.presenter.require_route && !found? && !handling?
          @found
        else
          if @presenter.presented?
            @found = true
            response.body = [@presenter.content]
          else
            @found = false unless found?
          end
        end
      end

      attr_accessor :processor_store, :binder, :context, :composer
      attr_reader :path

      def initialize(app = nil)
        @app = app
        @path = nil

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

        # TODO: this collapses the path
        # if @context.request.has_route_vars?
        #   @path = String.remove_route_vars(@context.request.route_path)
        # else
          @path = @context.request.path
        # end

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

      def process(contents, format)
        format = format.to_sym

        unless @app
          return contents
        end

        unless presenter = @app.presenter
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
        explicit ? raise(e) : logger.info(e.message)
      end

      def load_views
        @view_stores ||= {}

        @app.config.presenter.view_stores.each_pair { |name, path|
          next unless ViewStoreLoader.instance.modified?(name, path)
          @view_stores[name] = ViewStore.new(path, name)
        }
      end

      def load_bindings
        @binder = Binder.instance.reset

        @app.bindings.each_pair {|set_name, block|
          @binder.set(set_name, &block)
        }
      end

      def load_processors
        @processor_store = @app.processors
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

      def logger
        context.request.env['rack.logger'] || Pakyow.logger
      end
    end
  end
end
