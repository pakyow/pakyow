module Pakyow
  module Presenter
    def self.included(base)
      load_presenter_into(base)
    end

    def self.load_presenter_into(app_class)
      app_class.after :configure do
        app_class.template_store << TemplateStore.new(:default, config.presenter.path)

        if environment == :development
          app_class.handle Pakyow::Presenter::MissingView, as: 500 do
            respond_to :html do
              render "/missing_view"
            end
          end

          app_class.template_store << TemplateStore.new(:errors, File.join(File.expand_path("../../", __FILE__), "views", "errors"))

          # TODO: define view objects to render built-in errors
        end

        # TODO: the following handlers override the ones defined on the app
        # ideally global handlers could coexist (e.g. handle bugsnag, then present error page)
        # perhaps by executing all of 'em at once until halted or all called; feels consistent with
        # how multiple handlers are called in non-global cases; though load order would be important

        app_class.handle 404 do
          respond_to :html do
            render "/404"
          end
        end

        app_class.handle 500 do
          respond_to :html do
            render "/500"
          end
        end
      end
    end

    # Presents data in the view. Performs queries for view data. Understands binders / formatters.
    # Does not have access to the session, request, etc; only what is exposed to it from the route.
    # State is passed explicitly to the presenter, exposed by calling the `presentable` helper.
    #
    class Presenter
      attr_reader :view, :binders

      def initialize(view, binders: [])
        @view, @binders = view, binders
      end

      def find(*names)
        presenter_for(@view.find(*names))
      end

      def with
        yield self; self
      end

      def container(name)
        presenter_for(@view.container(name))
      end

      def partial(name)
        presenter_for(@view.partial(name))
      end

      def component(name)
        presenter_for(@view.component(name))
      end

      def form(name)
        presenter_for(@view.form(name))
      end

      def transform(data)
        presenter_for(@view.transform(data))
      end

      def bind(data)
        if binder = binder_for_current_scope
          if @view.is_a?(ViewSet)
            @view.views.zip(Array.ensure(data).map { |object| binder.new(object) }).each do |view, binder|
              bind_binder_to_view(binder, view)
            end
          else
            bind_binder_to_view(binder.new(data), @view)
          end
        else
          @view.bind(data)
        end

        presenter_for(@view)
      end

      def present(data)
        @view.transform(data) do |view, object|
          presenter_for(view).bind(object)
        end

        presenter_for(@view)
      end

      def append(view)
        presenter_for(@view.append(view))
      end

      def prepend(view)
        presenter_for(@view.append(view))
      end

      def after(view)
        presenter_for(@view.append(view))
      end

      def before(view)
        presenter_for(@view.append(view))
      end

      def replace(view)
        presenter_for(@view.append(view))
      end

      def remove
        presenter_for(@view.remove)
      end

      def clear
        presenter_for(@view.clear)
      end

      def text=(text)
        @view.text = text
      end

      def html=(html)
        @view.html = html
      end

      def count
        @view.count
      end

      def [](i)
        presenter_for(@view[i])
      end

      def to_html
        @view.to_html
      end

      alias :to_str :to_html

      private

      def presenter_for(view)
        Presenter.new(view, binders: binders)
      end

      def binder_for_current_scope
        binders.find { |binder|
          binder.name == @view.scoped_as
        }
      end

      def bind_binder_to_view(binder, view)
        bindable = binder.object

        view.props.each do |prop|
          value = binder[prop.name]

          if value.is_a?(BinderParts)
            bindable[prop.name] = value.content if value.content?
            view.attrs(value.non_content_parts)
          else
            bindable[prop.name] = value
          end
        end

        view.bind(bindable)
      end
    end

    class ViewPresenter < Presenter
      extend Support::ClassMaker
      CLASS_MAKER_BASE = "ViewPresenter".freeze

      class << self
        attr_reader :path, :block

        def make(path, state: nil, &block)
          klass = class_const_for_name(Class.new(self), name_from_path(path))

          klass.class_eval do
            @name = name
            @state = state
            @path = String.normalize_path(path)
            @block = block
          end

          klass
        end

        def name_from_path(path)
          return :root if path == "/"
          # TODO: fill in the rest of this
          # / => Root
          # /posts => Posts
          # /posts/show => PostsShow
        end
      end

      attr_reader :template, :page, :partials

      def initialize(template: nil, page: nil, partials: [], **args)
        @template, @page, @partials = template, page, partials
        @view = template.build(page).mixin(partials)
        super(@view, **args)
      end

      def to_html
        if block = self.class.block
          instance_exec(&block)
        end

        if title = page.info(:title)
          view.title = title
        end

        super
      end

      alias :to_str :to_html
    end
  end
end
