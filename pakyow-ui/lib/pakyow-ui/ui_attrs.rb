module Pakyow
  module UI
    class UIAttrs
      #TODO abstract the common bits from this + ui view to an instructable module
      def initialize
        @instructions = []
      end

      def instruct(method, value)
        @instructions << [method, value]
        self
      end

      def nested_instruct(method, value)
        attrs = UIAttrs.new
        @instructions << [method, value, attrs]
        attrs
      end

      def finalize
        @instructions.map { |instruction|
          if instruction[2].is_a?(UIAttrs)
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      def method_missing(method, value)
        nested_instruct(method, value)
      end

      def class(value)
        if value.respond_to?(:to_proc)
          value = value.to_proc
          value.call(ClassTranslator.new(self)).translate
        else
          instruct(:class, value)
        end
      end

      def id(*)
        method_missing(:id, nil)
      end

      class ClassTranslator
        def initialize(context)
          @context = context
          @attrs = @context.nested_instruct(:class, nil)
          @includes = []
          @removes = []
        end

        def <<(other)
          @includes << other
          self
        end
        alias_method :push, :<<

        def delete(other)
          @removes << other
          other
        end

        def translate
          @includes.flatten.uniq.each do |klass|
            @attrs.instruct(:insert, klass)
          end
          @removes.flatten.uniq.each do |klass|
            @attrs.instruct(:remove, klass)
          end
          @context
        end
      end
    end
  end
end
