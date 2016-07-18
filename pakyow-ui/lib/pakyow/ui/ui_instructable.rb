module Pakyow
  module UI
    # Helper methods for instructable objects.
    #
    # @api private
    module Instructable
      def self.included(klass)
        (@instructables ||= []) << klass
      end

      def self.instructable?(object)
        @instructables.select { |i|
          object.is_a?(i)
        }.any?
      end

      attr_reader :instructions
      attr_accessor :root

      def initialize
        @instructions = []
      end

      def instruct(method, data)
        @instructions << [clean_method(method), hashify(data)]
        self
      end

      def nested_instruct(method, data, scope = nil)
        view = nested_instruct_object(method, data, scope)
        view.root = self

        @instructions << [clean_method(method), hashify(data), view]
        view
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
          if Instructable.instructable?(instruction[2])
            instruction[2] = instruction[2].finalize
          end

          instruction
        }
      end

      private

      def mixin_bindings(data, bindings = {})
        data.map { |bindable|
          datum = bindable.to_hash.dup
          Pakyow::Presenter::Binder.instance.bindings_for_scope(scoped_as, bindings).keys.each do |key|
            result = Pakyow::Presenter::Binder.instance.value_for_scoped_prop(scoped_as, key, bindable, bindings, self)

            if result.is_a?(Hash)
              # we don't currently support view manipulations that occur in bindings
              # TODO: look into what it would take to support this
              result.delete(:view)

              content = result.delete(:content)
              if content.is_a?(Proc)
                content = content.call
              end

              datum[key] = {
                __content: content,
                __attrs: Hash[*result.flat_map { |k, v|
                  if v.is_a?(Proc)
                    attrs = UIAttrs.new
                    v.call(attrs)
                    [k, attrs.finalize]
                  else
                    [k, v]
                  end
                }]
              }
            else
              datum[key] = result
            end
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
        method.to_s.delete('=').to_sym
      end
    end
  end
end
