module Pakyow
  module Presenter
    class BindingEval
      include Pakyow::Helpers

      attr_reader :context, :bindable

      def initialize(prop, bindable, context)
        @parts = {}
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

      def eval(&block)
        instance_exec(value, bindable, context, &block)
        @parts.empty? ? nil : @parts
      end

      def part(name, &block)
        @parts[name.to_sym] = block
      end
    end
  end
end
