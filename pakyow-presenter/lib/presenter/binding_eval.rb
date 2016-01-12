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
        ret = instance_exec(value, bindable, context, &block)
        if ret.respond_to?(:to_hash)
          @parts.merge!(ret.to_hash)
        elsif ret
          @parts.merge!(content: ret)
        end
        @parts.empty? ? nil : @parts
      end

      def part(name, &block)
        @parts[name.to_sym] = block
        nil # Return nil so #part return value is ignored
      end
    end
  end
end
