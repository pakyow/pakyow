require_relative 'mutator'
require_relative 'channel_builder'
require_relative 'ui_view'

module Pakyow
  module UI
    class UI
      attr_reader :mutator

      def load(mutators, mutables)
        #TODO this is another pattern I see all over the place
        @mutator = Mutator.instance.reset

        mutators.each_pair do |scope, block|
          @mutator.set(scope, &block)
        end

        mutables.each_pair do |scope, block|
          @mutator.mutable(scope, &block)
        end
      end

      def mutated(scope, context = nil)
        MutationStore.instance.mutations(scope).each do |mutation|
          view = UIView.new(scope)

          data = Mutator.instance.mutable(scope, context).send(mutation[:query_name], *mutation[:query_args]).data
          Mutator.instance.mutate(mutation[:mutation].to_sym, view, data)

          Pakyow.app.socket.push(
            view.finalize,

            ChannelBuilder.build(
              scope: scope,
              mutation: mutation[:mutation].to_sym,
              qualifiers: mutation[:qualifiers],
              data: data,
              qualifications: mutation[:qualifications],
            )
          )
        end
      end

      def component(name)
        UIComponent.new(name)
      end
    end
  end
end
