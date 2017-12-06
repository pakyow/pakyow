# frozen_string_literal: true

require "pakyow/presenter/presentable"
require "pakyow/presenter/exceptions"
require "pakyow/presenter/renderer"

module Pakyow
  module Presenter
    # Presents data in the view. Performs queries for view data. Understands binders / formatters.
    # Does not have access to the session, request, etc; only what is exposed to it from the route.
    # State is passed explicitly to the presenter, exposed by calling the `presentable` helper.
    #
    class Presenter
      include Support::SafeStringHelpers

      attr_reader :view, :binders

      def initialize(view, binders: [], paths: nil)
        @view, @binders, @paths = view, binders, paths
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

      def to_html(clean: true)
        @view.to_html(clean: clean)
      end

      alias :to_str :to_html

      private

      def presenter_for(view, type: Presenter)
        type.new(view, binders: binders, paths: @paths)
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

            value.non_content_parts.each_pair do |key, value_part|
              prop_view.attrs[key] = value_part
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
