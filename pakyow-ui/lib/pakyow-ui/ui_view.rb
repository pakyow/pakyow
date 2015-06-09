require_relative 'ui_attrs'

module Pakyow
  module UI
    class UIView
      attr_reader :instructions

      def initialize(scope)
        @scope = scope
        @instructions = []
      end

      def scoped_as
        @scope
      end

      def instruct(method, data)
        @instructions << [clean_method(method), hashify(data)]
        self
      end

      def nested_instruct(method, data, scope = nil)
        view = UIView.new(scope || @scope)
        @instructions << [clean_method(method), hashify(data), view]
        view
      end

      def attrs_instruct
        attrs = UIAttrs.new
        @instructions << [:attrs, nil, attrs]
        attrs
      end

      # Returns an instruction set for all view transformations.
      #
      # e.g. a value-less transformation:
      # [[:remove, nil]]
      #
      # e.g. a transformation with a value:
      # [[:text=, 'foo']]
      #
      # e.g. a nested transformation
      # [[:scope, :post, [[:remove, nil]]]]
      def finalize
        @instructions.map { |instruction|
          if instruction[2].is_a?(UIView) || instruction[2].is_a?(UIAttrs)
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      ### view methods w/o args

      %i[
        remove
        clear
      ].each do |method|
        define_method method do
          instruct(method, nil)
        end
      end

      ### view methods w/ args

      %i[
        title=
        text=
        html=
        append
        prepend
        after
        before
        replace
      ].each do |method|
        define_method method do |value|
          instruct(method, value.to_s)
        end
      end

      ### misc view methods

      def with
        self
      end

      def match(data)
        instruct(:match, Array.ensure(data))
      end

      def scope(name)
        nested_instruct(:scope, name.to_s, name)
      end

      def attrs
        attrs_instruct
      end

      ### view methods that change context

      %i[
        prop
        component
      ].each do |method|
        define_method method do |value|
          nested_instruct(method, value.to_s)
        end
      end

      ### view methods that continue into a new context

      def for(data, &block)
        nested = nested_instruct(:for, data)
        Array.ensure(data).each do |datum|
          if block.arity == 1
            nested.instance_exec(datum, &block)
          else
            block.call(nested, datum)
          end
        end
      end

      def for_with_index(data, &block)
        i = 0
        self.for(data) do |view, datum|
          if block.arity == 2
            view.instance_exec(datum, i, &block)
          else
            block.call(view, datum, i)
          end

          i += 1
        end
      end

      def repeat(data, &block)
        nested = nested_instruct(:repeat, data)
        Array.ensure(data).each do |datum|
          if block.arity == 1
            nested.instance_exec(datum, &block)
          else
            block.call(nested, datum)
          end
        end
      end

      def repeat_with_index(data, &block)
        i = 0
        repeat(data) do |view, datum|
          if block.arity == 2
            view.instance_exec(datum, i, &block)
          else
            block.call(view, datum, i)
          end

          i += 1
        end
      end

      def bind(data, bindings: {}, context: nil, &block)
        #TODO handle context?

        data = Array.ensure(data)
        nested = nested_instruct(:bind, data)
        return self unless block_given?

        data.each do |datum|
          datum = mixin_bindings(datum)

          if block.arity == 1
            nested.instance_exec(datum, &block)
          else
            block.call(nested, datum)
          end
        end
      end

      def bind_with_index(data, bindings: {}, context: nil, &block)
        i = 0
        bind(data, bindings: bindings, context: context) do |view, datum|
          if block.arity == 2
            view.instance_exec(datum, i, &block)
          else
            block.call(view, datum, i)
          end

          i += 1
        end
      end

      def apply(data, bindings: {}, context: nil, &block)
        #TODO handle context?

        data = Array.ensure(data)
        nested = nested_instruct(:apply, data)
        return self unless block_given?

        data.each do |datum|
          datum = mixin_bindings(datum)

          if block.arity == 1
            nested.instance_exec(datum, &block)
          else
            block.call(nested, datum)
          end
        end
      end

      private

      #TODO make this work
      def mixin_bindings(data)
        data
      end

      def hashify(data)
        return data unless data.is_a?(Array)
        data.map { |datum|
          if datum.respond_to?(:to_h)
            datum.to_h
          else
            datum
          end
        }
      end

      def clean_method(method)
        method.to_s.gsub('=', '').to_sym
      end
    end
  end
end
