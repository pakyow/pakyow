module Pakyow
  module Presenter
    class BindingEval
      attr_reader :context, :bindable

      def initialize(prop, bindable, context)
        @prop = prop
        @bindable = bindable
        @context = context
      end

      def value
        bindable[@prop]
      end
    end
  end
end

