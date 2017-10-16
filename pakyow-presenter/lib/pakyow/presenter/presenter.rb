module Pakyow
  module Presenter
    def self.included(base)
      load_presenter_into(base)
    end

    def self.load_presenter_into(app_class)
      app_class.after :load do
        app_class.template_store << TemplateStore.new(:default, config.presenter.path, processor: ProcessorCaller.new(app_class.state[:processor].instances))

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
      include Support::SafeStringHelpers

      attr_reader :view, :binders

      def initialize(view, binders: [], controller: nil)
        @view, @binders, @controller = view, binders, controller
      end

      def find(*names)
        presenter_for(@view.find(*names))
      end

      def title(value)
        if title_view = @view.title
          # FIXME: this should be `text=` once supported by `StringNode`
          title_view.html = value
        else
          # TODO: should we add the title node, or raise an error?
        end
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
        presenter_for(@view.form(name), type: FormPresenter)
      end

      def transform(data)
        presenter_for(@view.transform(data))
      end

      def bind(data)
        if binder = binder_for_current_scope
          bind_binder_to_view(binder.new(data), @view)
        else
          @view.bind(data)
        end

        presenter_for(@view)
      end

      def present(data)
        @view.transform(data) do |view, object|
          yield view, object if block_given?

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

      def decorated?
        @view.decorated?
      end

      def container?
        @view.container?
      end

      def partial?
        @view.partial?
      end

      def component?
        @view.component?
      end

      def form?
        @view.form?
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

      def presenter_for(view, type: Presenter)
        type.new(view, binders: binders, controller: @controller)
      end

      def binder_for_current_scope
        binders.find { |binder|
          binder.name == @view.name
        }
      end

      def bind_binder_to_view(binder, view)
        bindable = binder.object

        view.props.each do |prop|
          value = binder[prop.name]

          if value.is_a?(BindingParts)
            next unless prop_view = view.find(prop.name)

            value.accept(*prop_view.label(:include)&.split(" "))
            value.reject(*prop_view.label(:exclude)&.split(" "))

            bindable[prop.name] = value.content if value.content?

            value.non_content_parts.each_pair do |key, value|
              prop_view.attrs[key] = value
            end
          else
            bindable[prop.name] = value
          end
        end

        view.bind(bindable)
      end
    end
  end
end
