require_relative 'ui_attrs'
require_relative 'ui_instructable'

module Pakyow
  module UI
    # Translates view transformations to instructions.
    #
    # @api private
    class UIView
      include Instructable

      def initialize(scope)
        super()
        @scope = scope
      end

      def nested_instruct_object(_method, _data, scope)
        UIView.new(scope || @scope)
      end

      def scoped_as
        @scope
      end

      def attrs_instruct
        attrs = UIAttrs.new
        @instructions << [:attrs, nil, attrs]
        attrs
      end

      ### view methods w/o args

      %i(
        remove
        clear
      ).each do |method|
        define_method method do
          instruct(method, nil)
        end
      end

      ### view methods w/ args

      %i(
        title=
        text=
        html=
        append
        prepend
        after
        before
        replace
      ).each do |method|
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

      %i(
        prop
        component
      ).each do |method|
        define_method method do |value|
          nested_instruct(method, value.to_s)
        end
      end

      ### view methods that continue into a new context

      def for(data, &block)
        nested = nested_instruct(:for, data)
        Array.ensure(data).each do |datum|
          sub = UIView.new(@scope)

          if block.arity == 1
            sub.instance_exec(datum, &block)
          else
            block.call(sub, datum)
          end

          nested.instructions << sub.finalize
        end
      end

      def for_with_index(*args, &block)
        self.for(*args, &block)
      end

      def repeat(data, &block)
        nested = nested_instruct(:repeat, data)
        Array.ensure(data).each do |datum|
          sub = UIView.new(@scope)

          if block.arity == 1
            sub.instance_exec(datum, &block)
          else
            block.call(sub, datum)
          end

          nested.instructions << sub.finalize
        end
      end

      def repeat_with_index(*args, &block)
        repeat(*args, &block)
      end

      def bind(data, bindings: {}, context: nil, &block)
        # TODO: handle context?

        data = mixin_bindings(Array.ensure(data), bindings)
        nested = nested_instruct(:bind, data)
        return self unless block_given?

        data.each do |datum|
          sub = UIView.new(@scope)

          if block.arity == 1
            sub.instance_exec(datum, &block)
          else
            block.call(sub, datum)
          end

          nested.instructions << sub.finalize
        end
      end

      def bind_with_index(*args, &block)
        bind(*args, &block)
      end

      def apply(data, bindings: {}, context: nil, &block)
        # TODO: handle context?

        data = mixin_bindings(Array.ensure(data), bindings)
        nested = nested_instruct(:apply, data)
        return self unless block_given?

        data.each do |datum|
          sub = UIView.new(@scope)

          if block.arity == 1
            sub.instance_exec(datum, &block)
          else
            block.call(sub, datum)
          end

          nested.instructions << sub.finalize
        end
      end
    end
  end
end
