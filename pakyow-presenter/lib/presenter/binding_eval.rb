module Pakyow
  module Presenter
    class BindingEval
      include Pakyow::Helpers

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
