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
        @presenter.prepare_for_request(@context)
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

      attr_accessor :processor_store, :binder, :path, :template, :page, :context

      def initialize
        setup
      end

      def setup
        @view, @template, @page = nil
        @constructed = false
        self.store   = :default
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

        return unless @path
        setup_for_path
      end

      def load
        load_processors
        load_views
        load_bindings
      end

      def prepare_for_request(context)
        @context = context

        if @context.request.has_route_vars?
          @path = StringUtils.remove_route_vars(@context.request.route_path)
        else
          @path = @context.request.path
        end

        setup
      end

      def presented?
        ensure_construction
        @constructed
      end

      def content
        return unless view
        view.to_html
      end

      def view
        ensure_construction
        @view
      end

      def partial(name)
        store.partial(@path, name)
      end

      def view=(view)
        @view = view
        @view.context = @context
        @constructed = true
      end

      def template=(template)
        unless template.is_a?(Template)
          # get template by name
          template = store.template(template)
        end

        @template = template
        @constructed = false
      end

      def page=(page)
        @page = page
        @constructed = false
      end

      def path=(path)
        @path = path
        setup_for_path(true)
      end

      def ensure_construction
        # only construct once
        return if @constructed

        # if no template/page was found, we can't construct
        return if @template.nil? || @page.nil?

        # construct
        @view = @template.dup.build(@page)
        @view.context = @context
        @constructed = true
      end

      protected

      def setup_for_path(explicit = false)
        self.template = store.template(@path)
        self.page     = store.page(@path)
        self.view     = store.view(@path)

        @constructed = true
      rescue MissingView => e # catches no view path error
        explicit ? raise(e) : Pakyow.logger.debug(e.message)
        @constructed = false
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
