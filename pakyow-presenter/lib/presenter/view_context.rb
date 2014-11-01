module Pakyow
  module Presenter
    # This is a wrapper for View / ViewCollection that passes the current
    # AppContext to all binding methods. This object is expected to only
    # be used from the app, not internally.
    #
    class ViewContext
      def initialize(view, context)
        @view = view
        @context = context
      end

      %i(bind bind_with_index apply).each do |method|
        define_method(method) do |data, **kargs, &block|
          kargs[:ctx] ||= @context
          ret = @view.send(method, data, **kargs, &block)
          handle_return_value(ret)
        end
      end

      def working
        @view
      end

      def method_missing(method, *args, **kargs, &block)
        ret = @view.send(method, *args, &block)
        handle_return_value(ret)
      end

      private

      VIEW_CLASSES = [View, ViewCollection]
      def handle_return_value(value)
        if value.class.ancestors.any? { |a| VIEW_CLASSES.include?(a) }
          @view = value
          return self
        end

        value
      end
    end
  end
end
