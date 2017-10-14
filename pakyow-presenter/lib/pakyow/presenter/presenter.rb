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

          if value.is_a?(BinderParts)
            next unless prop_view = view.find(prop.name)

            value.accept(*prop_view.attrs[:"data-include"]&.split(" "))
            value.reject(*prop_view.attrs[:"data-exclude"]&.split(" "))

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

    class FormPresenter < Presenter
      METHOD_OVERRIDES = {
        update: "patch".freeze,
        replace: "put".freeze,
        remove: "delete".freeze
      }.freeze

      SUPPORTED_ACTIONS = %i(create update replace remove)

      FORM_METHOD_DEFAULT = "post".freeze

      def setup(action, object = nil)
        action = action.to_sym

        raise ArgumentError.new("Expected action to be one of: #{SUPPORTED_ACTIONS.join(", ")}") unless SUPPORTED_ACTIONS.include?(action)

        yield self if block_given?

        @view.attrs.method = FORM_METHOD_DEFAULT
        @view.attrs.action = form_action(action, object)

        if method_override_required?(action)
          @view.prepend(method_override_input(action))
        end

        if object
          @view.bind(object)
        end

        set_input_names
      end

      def create(object)
        yield self if block_given?
        setup :create, object
      end

      def update(object)
        yield self if block_given?
        setup :update, object
      end

      def replace(object)
        yield self if block_given?
        setup :replace, object
      end

      def remove(object)
        yield self if block_given?
        setup :remove, object
      end

      def options_for(field, options = nil)
        create_select_options(field, options ||= yield)
      end

      def value_for(field, value = nil)
        set_value(field, value ||= yield)
      end

      protected

      def form_action(action, object)
        @controller.path_to(@view.name, action, **form_action_params(object))
      end

      def form_action_params(object)
        params = {}
        params[:"#{@view.name}_id"] = object[:id] if object
        params
      end

      def method_override_required?(action)
        METHOD_OVERRIDES.include?(action)
      end

      def method_override(action)
        METHOD_OVERRIDES[action]
      end

      def method_override_input(action)
        # FIXME: avoid creating a new view once string values are supported (there's no need to parse)
        View.new("<input type=\"hidden\" name=\"_method\" value=\"#{method_override(action)}\">")
      end

      def set_input_names
        @view.props.each do |prop|
          prop.attributes[:name] = "#{@view.name}[#{prop.name}]" if prop.attributes[:name].nil?
        end
      end

      def create_select_options(field, values)
        option_nodes = Oga::XML::Document.new

        until values.length == 0
          catch :optgroup do
            o = values.first

            # an array containing value/content
            if o.is_a?(Array)
              node = Oga::XML::Element.new(name: 'option')
              node.inner_text = ensure_html_safety(o[1].to_s)
              node.set('value', ensure_html_safety(o[0].to_s))
              option_nodes.children << node
              values.shift
            else # likely an object (e.g. string); start a group
              node_group = Oga::XML::Element.new(name: 'optgroup')
              node_group.set('label', ensure_html_safety(o.to_s))
              option_nodes.children << node_group

              values.shift

              values[0..-1].each_with_index { |o2,i2|
                # starting a new group
                throw :optgroup unless o2.is_a?(Array)

                node = Oga::XML::Element.new(name: 'option')
                node.inner_text = ensure_html_safety(o2[1].to_s)
                node.set('value', ensure_html_safety(o2[0].to_s))
                node_group.children << node
                values.shift
              }
            end
          end
        end

        field_view = @view.find(field)[0]
        raise ArgumentError.new("Couldn't find a field named #{field}") if field_view.nil?

        # remove existing options
        field_view.clear

        # add generated options
        # FIXME: avoid creating a new view once string values are supported (there's no need to parse)
        # we can also build up options as an html string rather than an oga document
        field_view.append(View.new(option_nodes.to_xml))
      end

      def set_value(field, value)
        field_view = @view.find(field)[0]
        raise ArgumentError.new("Couldn't find a field named #{field}") if field_view.nil?
        raise ArgumentError.new("Expected #{field} to be of type checkbox or radio") unless Form::CHECKED_TYPES.include?(field_view.object.attributes[:type])

        field_view.object.attributes[:value] = value
      end
    end
  end
end
