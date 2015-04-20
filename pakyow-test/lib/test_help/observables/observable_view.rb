require_relative '../observable'

module Pakyow
  module TestHelp
    class ObservableView
      include Observable
      attr_reader :view, :presenter

      def initialize(view, presenter)
        @view = view
        @presenter = presenter
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

      def applied?(data)
        presenter.observed?(view.scoped_as, :apply, data: data)
      end

      def bound?(value)
        #TODO handle checking bound values of form fields
        view[0].text == value
      end

      def apply(data, bindings: {}, context: nil, &block)
        presenter.observing(view.scoped_as, :apply, data: data, bindings: bindings, context: context, block: block)
        handle_value(view.apply(data, bindings: bindings, context: context, &block))
      end
    end
  end
end
