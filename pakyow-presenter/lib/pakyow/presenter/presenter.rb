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

      def find(scope)
        presenter_for(view.scope(scope))
      end

      def present(data)
        data = Array.ensure(data)

        if binder = binder_for_current_scope
          view.repeat(data.map { |object| binder.new(object) }) do |view, binder|
            bindable = binder.object
            view.doc.props.keys.each do |prop_name|
              value = binder[prop_name]

              if value.is_a?(BinderParts)
                bindable[prop_name] = value.content if value.content?
                view.attrs(value.non_content_parts)
              else
                bindable[prop_name] = value
              end
            end

            view.bind(bindable)
          end
        else
          view.apply(data)
        end
      end

      def to_html
        view.to_html
      end

      alias :to_str :to_html

      private

      def presenter_for(view)
        Presenter.new(view, binders: binders)
      end

      def binder_for_current_scope
        binders.find { |binder|
          binder.scope == view.scoped_as
        }
      end
    end

    class ViewPresenter < Presenter
      class << self
        attr_reader :name, :path, :block

        def make(path, state: nil, &block)
          klass = const_for_presenter_named(Class.new(self), name_from_path(path))

          klass.class_eval do
            @path = String.normalize_path(path)
            @name = name
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

        def const_for_presenter_named(presenter_class, name)
          return presenter_class if name.nil?

          # convert snake case to camel case
          class_name = "#{name.to_s.split('_').map(&:capitalize).join}ViewPresenter"

          if Object.const_defined?(class_name)
            presenter_class
          else
            Object.const_set(class_name, presenter_class)
          end
        end
      end

      attr_reader :template, :page, :partials

      def initialize(template: nil, page: nil, partials: {}, **args)
        @template, @page, @partials = template, page, partials
        @view = template.build(page).includes(partials)
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
