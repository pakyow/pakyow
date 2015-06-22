module Pakyow
  module UI
    #TODO UIAttrs, UIComponent, and UIView are so similar
    # abstract the common bits into a UIInstruct module
    class UIComponent
      attr_reader :name, :view, :instructions

      def initialize(name)
        @name = name
        @instructions = []
      end

      def push
        #TODO make it work with qualifiers
        Pakyow.app.socket.push(
          { instruct: finalize },

          ChannelBuilder.build(
            component: name,
          )
        )
      end

      def instruct(method, data)
        @instructions << [clean_method(method), hashify(data)]
        self
      end

      def nested_instruct(method, data, scope = nil)
        view = UIComponent.new(scope || @scope)
        @instructions << [clean_method(method), hashify(data), view]
        view
      end

      def scope(name)
        nested_instruct(:scope, name.to_s, name)
      end

      def append(data)
        instruct(:append, data)
      end

      def prepend(data)
        instruct(:prepend, data)
        push
      end

      def finalize
        @instructions.map { |instruction|
          if instruction[2].is_a?(UIView) || instruction[2].is_a?(UIAttrs) || instruction[2].is_a?(UIComponent)
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      private

      def mixin_bindings(data, bindings = {})
        data.map { |bindable|
          datum = bindable.to_hash
          Binder.instance.bindings_for_scope(scoped_as, bindings).keys.each do |key|
            datum[key] = Binder.instance.value_for_scoped_prop(scoped_as, key, bindable, bindings, self)
          end

          datum
        }
      end

      def hashify(data)
        return hashify_datum(data) unless data.is_a?(Array)

        data.map { |datum|
          hashify_datum(datum)
        }
      end

      def hashify_datum(datum)
        if datum.respond_to?(:to_hash)
          datum.to_hash
        else
          datum
        end
      end

      def clean_method(method)
        method.to_s.gsub('=', '').to_sym
      end
    end
  end
end
