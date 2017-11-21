# frozen_string_literal: true

module Pakyow
  module TestHelp
    module Realtime
      class ObservableMutator
        include Singleton

        def initialize
          reset
        end

        def reset
          @mutations = []
        end

        def mutate(mutation_name, view, data)
          context = ObservableMutateContext.new(
            Pakyow::UI::Mutator.instance.mutate(mutation_name, view, data)
          )

          @mutations << {
            mutation_name: mutation_name,
            context: context,
            view: view,
            data: data
          }

          context
        end

        def mutated?(observable_view, mutation_name, data: nil)
          if mutation_name.nil? && data.nil?
            @mutations.each do |mutation|
              return true if mutation[:view].subject.observable == observable_view.observable
            end
          elsif mutation_name && data.nil?
            @mutations.each do |mutation|
              return true if mutation[:mutation_name] == mutation_name && mutation[:view].subject.observable == observable_view.observable
            end
          elsif data && mutation_name.nil?
            @mutations.each do |mutation|
              return true if mutation[:view].subject.observable == observable_view.observable && mutation[:data] == data
            end
          else
            @mutations.each do |mutation|
              return true if mutation[:mutation_name] == mutation_name && mutation[:view].subject.observable == observable_view.observable && mutation[:data] == data
            end
          end

          false
        end

        def subscribed?(observable_view)
          @mutations.each do |mutation|
            return true if mutation[:context].subscribed? && mutation[:view].subject.observable == observable_view.observable
          end

          false
        end
      end

      class ObservableMutateContext
        def initialize(context)
          @context = context
          @subscriptions = []
        end

        def subscribe(qualifications = {})
          @subscriptions << qualifications
        end

        def subscribed?
          !@subscriptions.empty?
        end
      end
    end
  end
end
