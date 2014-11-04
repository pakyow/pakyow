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
        if bindable.is_a?(Hash)
          bindable[@prop]
        elsif bindable.respond_to?(@prop)
          bindable.send(@prop)
        end
      end
    end
  end
end
