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
        #TODO handle context?

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
        #TODO handle context?

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

      private

      def mixin_bindings(data, bindings = {})
        data.map { |bindable|
          datum = bindable.to_hash
          Pakyow::Presenter::Binder.instance.bindings_for_scope(scoped_as, bindings).keys.each do |key|
            datum[key] = Pakyow::Presenter::Binder.instance.value_for_scoped_prop(scoped_as, key, bindable, bindings, self)
          end

          datum
        }
      end

      def hashify(data)
        return data unless data.is_a?(Array)

        data.map { |datum|
          if datum.respond_to?(:to_hash)
            datum.to_hash
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
