require_relative 'mutation_set'
require_relative 'mutate_context'

module Pakyow
  module UI
    # Performs mutations on views.
    #
    # @api private
    class Mutator
      include Singleton

      attr_reader :sets

      # @api private
      def initialize
        reset
      end

      def reset
        @sets = {}
        @mutables = {}
        self
      end

      def set(scope, &block)
        @sets[scope] = MutationSet.new(&block)
      end

      def mutable(scope, context = nil, &block)
        if block_given?
          @mutables[scope] = block
        else
          # TODO: inefficient to have to execute the block each time
          Mutable.new(context, scope, &@mutables[scope])
        end
      end

      def mutation(scope, name)
        if mutations = mutations_by_scope(scope)
          mutations.mutation(name)
        end
      end

      # TODO: rename to mutation_set_for_scope
      def mutations_by_scope(scope)
        @sets[scope]
      end

      def mutate(mutation_name, view, data)
        if mutation = mutation(view.scoped_as, mutation_name)
          if data.is_a?(MutableData)
            working_data = data.data
          else
            working_data = data
          end

          view.instance_exec(view, working_data, &mutation[:fn])
          MutateContext.new(mutation, view, data)
        end
      end
    end
  end
end
