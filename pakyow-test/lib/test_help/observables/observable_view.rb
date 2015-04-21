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

      def observable
        view
      end

      def with
        yield self
      end

      def for(data, &block)
        view.for(data) do |view, datum|
          block.call(handle_value(view), datum)
        end
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

      def bound?(value)
        #TODO handle checking bound values of form fields
        view[0].text == value
      end

      def apply(data, bindings: {}, context: nil, &block)
        presenter.observing(view.scoped_as, :apply, traversal, data: data, bindings: bindings, context: context, block: block)

        result = view.apply(data, bindings: bindings, context: context) do |view, datum|
          block.call(handle_value(view), datum)
        end

        handle_value(result)
      end
    end
  end
end
