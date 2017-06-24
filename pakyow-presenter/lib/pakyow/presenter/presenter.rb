module Pakyow
  module Presenter
    module Presentable
      attr_reader :presentables

      def initialize(*args)
        @presentables = self.class.presentables.dup
        super
      end

      def presentable(*args)
        presentables.concat(args).uniq!
      end

      module ClassMethods
        def presentable(*args)
          presentables.concat(args).uniq!
        end

        def presentables
          @presentables ||= []
        end
      end
    end
  end
end

module Pakyow
  class Router
    prepend Presenter::Presentable
    extend Presenter::Presentable::ClassMethods
  end
end

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
          class_name = "#{name.to_s.split('_').map(&:capitalize).join}Presenter"

          if Object.const_defined?(class_name)
            presenter_class
          else
            Object.const_set(class_name, presenter_class)
          end
        end
      end

      attr_reader :template, :page, :partials

      def initialize(presenters: [], template: nil, page: nil, partials: {})
        @template, @page, @partials = template, page, partials
      end

      def to_html
        if block = self.class.block
          instance_exec(&block)
        end

        view = template.dup.build(page).includes(partials)

        if title = page.info(:title)
          view.title = title
        end

        return view.to_html
      end

      alias :to_str :to_html
    end
  end

  class Router
    def_delegators :controller, :render
  end

  class Controller
    def render(path = request.route_path || request.path, as: nil)
      if info = find_info_for(path)
        unless presenter = find_presenter_for(as || path)
          presenter = Presenter::Presenter
        end

        presenter_instance = presenter.new(presenters: app.state_for(:presenter), **info)
        current_router.presentables.each do |presentable|
          begin
            value = current_router.__send__(presentable)
          rescue NoMethodError
            fail "could not find presentable state for `#{presentable}' on #{current_router}"
          end

          presenter_instance.define_singleton_method presentable do
            value
          end
        end

        halt StringIO.new(presenter_instance)
      elsif found? # matched a route, but couldn't find a view to present
        raise Presenter::MissingView.new("No view at path `#{path}'")
      end
    end

    protected

    def find_info_for(path)
      collapse_path(path) do |collapsed_path|
        if info = info_for_path(collapsed_path)
          return info
        end
      end

      nil
    end

    def find_presenter_for(path)
      collapse_path(path) do |collapsed_path|
        if presenter = presenter_for_path(collapsed_path)
          return presenter
        end
      end

      nil
    end

    def info_for_path(path)
      app.state_for(:template_store).lazy.map { |store|
        store.at_path(path)
      }.find(&:itself)
    end

    def presenter_for_path(path)
      app.state_for(:view).lazy.find { |presenter|
        presenter.path == path
      }
    end

    def collapse_path(path)
      yield path; return if path == "/"

      parts = path.split("/").keep_if { |part|
        part[0] != ":"
      }

      parts.count.downto(1) do |count|
        yield parts.take(count).join("/")
      end
    end
  end
end
