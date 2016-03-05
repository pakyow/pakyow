require_relative '../observable'

module Pakyow
  module TestHelp
    class ObservableView
      include Observable
      attr_reader :view, :presenter, :traversal

      def initialize(view, presenter, traversal)
        @view = view
        @presenter = presenter
        @traversal = traversal
      end

      def ==(other)
        doc == other.doc
      end

      def observable
        view
      end

      def with(&block)
        if block.arity == 0
          instance_exec(&block)
        else
          yield(self)
        end

        self
      end

      def for(data, &block)
        view.for(data) do |view, datum|
          block.call(handle_value(view), datum)
        end
      end

      def bind(data, bindings: {}, context: nil, &block)
        presenter.observing(view.scoped_as, :bind, traversal, data: data, bindings: bindings, context: context, block: block)

        result = view.bind(data, bindings: bindings, context: context) do |view, datum|
          block.call(handle_value(view), datum) unless block.nil?
        end

        handle_value(result)
      end

      def apply(data, bindings: {}, context: nil, &block)
        presenter.observing(view.scoped_as, :apply, traversal, data: data, bindings: bindings, context: context, block: block)

        result = view.apply(data, bindings: bindings, context: context) do |view, datum|
          block.call(handle_value(view), datum) unless block.nil?
        end

        handle_value(result)
      end

      def append(appendable_view)
        presenter.observing(view.scoped_as, :append, traversal, view: appendable_view)
        handle_value(view.append(appendable_view))
      end

      def prepend(prependable_view)
        presenter.observing(view.scoped_as, :prepend, traversal, view: prependable_view)
        handle_value(view.prepend(prependable_view))
      end

      def after(after_view)
        presenter.observing(view.scoped_as, :after, traversal, view: after_view)
        handle_value(view.after(after_view))
      end

      def before(before_view)
        presenter.observing(view.scoped_as, :before, traversal, view: before_view)
        handle_value(view.before(before_view))
      end

      def replace(replace_view)
        presenter.observing(view.scoped_as, :replace, traversal, view: replace_view)
        handle_value(view.replace(replace_view))
      end

      def scope?(name)
        view.scope(name).length > 0
      end

      def prop?(name)
        view.prop(name).length > 0
      end

      def exists?
        view.length > 0
      end

      def applied?(data = nil)
        values = {}
        values[:data] = data if data
        presenter.observed?(view.scoped_as, :apply, traversal, values)
      end

      def bound?(data = nil)
        if view.first.doc.has_attribute?(:'data-scope')
          values = {}
          values[:data] = data if data
          presenter.observed?(view.scoped_as, :bind, traversal, values)
        else
          data && view[0].text == data
        end
      end

      def appended?(appended_view = nil)
        values = {}
        values[:view] = appended_view if appended_view
        presenter.observed?(view.scoped_as, :append, traversal, values)
      end

      def prepended?(prepended_view = nil)
        values = {}
        values[:view] = prepended_view if prepended_view
        presenter.observed?(view.scoped_as, :prepend, traversal, values)
      end

      def after?(after_view = nil)
        values = {}
        values[:view] = after_view if after_view
        presenter.observed?(view.scoped_as, :after, traversal, values)
      end

      def before?(before_view = nil)
        values = {}
        values[:view] = before_view if before_view
        presenter.observed?(view.scoped_as, :before, traversal, values)
      end

      def replaced?(replace_view = nil)
        values = {}
        values[:view] = replace_view if replace_view
        presenter.observed?(view.scoped_as, :replace, traversal, values)
      end

      def mutated?(mutation = nil, data: nil)
        Pakyow::TestHelp::Realtime::ObservableMutator.instance.mutated?(self, mutation, data: data)
      end

      def subscribed?
        Pakyow::TestHelp::Realtime::ObservableMutator.instance.subscribed?(self)
      end
    end
  end
end
