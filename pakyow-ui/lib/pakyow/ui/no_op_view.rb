require_relative 'mock_mutation_eval'

module Pakyow
  module Presenter
    # Stands in for a real View object and makes any attempted transformation
    # a no-op.
    #
    # @api private
    class NoOpView
      VIEW_CLASSES = [ViewContext]

      # The arities of misc view methods that switch the behavior from
      # instance_exec to yield.
      #
      EXEC_ARITIES = { with: 0, for: 1, for_with_index: 2, repeat: 1,
                       repeat_with_index: 2, bind: 1, bind_with_index: 2,
                       apply: 1 }

      def initialize(view, context)
        @view = view
        @context = context
      end

      def is_a?(klass)
        @view.is_a?(klass)
      end

      # View methods that should be a no-op
      #
      %i(bind bind_with_index apply).each do |method|
        define_method(method) do |_data, **_kargs, &_block|
          self
        end
      end

      def mutate(mutator, with: nil, data: nil)
        MockMutationEval.new(mutator, with || data, self)
      end

      # Pass these through, handling the return value.
      #
      def method_missing(method, *args, &block)
        ret = @view.send(method, *args, &wrap(method, &block))
        handle_return_value(ret)
      end

      private

      def view?(obj)
        VIEW_CLASSES.include?(obj.class)
      end

      # Returns a new context for returned views, or the return value.
      #
      def handle_return_value(value)
        return NoOpView.new(value, @context) if view?(value)

        value
      end

      # Wrap the block, substituting the view with the current view context.
      #
      def wrap(method, &block)
        return if block.nil?

        proc do |*args|
          ctx = args.map! { |arg|
            view?(arg) ? NoOpView.new(arg, @context) : arg
          }.find { |arg| arg.is_a?(ViewContext) }

          case block.arity
          when EXEC_ARITIES[method]
            # Rejecting ViewContext handles the edge cases around the order of
            # arguments from view methods (since view is not present in some
            # situations and when it is present, is always the first arg).
            ctx.instance_exec(*args.reject { |arg|
              arg.is_a?(ViewContext)
            }, &block)
          else
            block.call(*args)
          end
        end
      end
    end
  end
end
