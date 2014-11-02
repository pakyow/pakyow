module Pakyow
  module Presenter
    # This is a wrapper for View / ViewCollection that passes the current
    # AppContext to all binding methods. This object is expected to only
    # be used from the app, not internally.
    #
    class ViewContext
      VIEW_CLASSES = [View, ViewCollection]

      # The arities of misc view methods that switch the behavior from
      # instance_exec to yield.
      #
      EXEC_ARITIES = { with: 0, for: 1, for_with_index: 2, repeat: 1,
        repeat_with_index: 2, bind: 1, bind_with_index: 2, apply: 1 }

      def initialize(view, context)
        @view = view
        @context = context
      end

      # View methods that expect context, so it can be mixed in.
      #
      %i[bind bind_with_index apply].each do |method|
        define_method(method) do |data, **kargs, &block|
          kargs[:ctx] ||= @context
          ret = @view.send(method, data, **kargs, &wrap(method, &block))
          handle_return_value(ret)
        end
      end

      # View methods that return views, but don't expect context.
      #
      %i[with for for_with_index repeat repeat_with_index].each do |method|
        define_method(method) do |*args, &block|
          ret = @view.send(method, *args, &wrap(method, &block))
          handle_return_value(ret)
        end
      end

      # Pass these through, handling the return value.
      #
      def method_missing(method, *args, &block)
        ret = @view.send(method, *args, &block)
        handle_return_value(ret)
      end

      private

      # Returns a new context for returned views, or the return value.
      #
      def handle_return_value(value)
        if value.class.ancestors.any? { |a| VIEW_CLASSES.include?(a) }
          return ViewContext.new(value, @context)
        end

        value
      end

      # Wrap the block, effectively substituting the view with the current
      # view context.
      #
      def wrap(method, &block)
        Proc.new do |*args|
          ctx = nil
          args.map! { |arg|
            if VIEW_CLASSES.include?(arg.class)
              ctx = ViewContext.new(arg, @context)
            else
              arg
            end
          }

          next if block.nil?
          case block.arity
            when EXEC_ARITIES[method]
              # Rejecting ViewContext handles the edge cases around the order of
              # arguments from view methods (since view is not present in some
              # situations and when it is present, is always the first arg).
              #
              ctx.instance_exec(*args.reject { |arg| arg.is_a?(ViewContext) }, &block)
            else
              block.call(*args)
          end
        end
      end
    end
  end
end
