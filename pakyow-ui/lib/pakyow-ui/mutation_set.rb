module Pakyow
  module UI
    class MutationSet
      attr_reader :mutations

      def initialize(&block)
        @mutations = {}
        instance_exec(&block)
      end

      #NOTE I do have some concerns about defining qualifiers in this way;
      # mainly because it will lead to having lots of versions of the same
      # mutator just so the proper channels will be created.
      #
      # It's could end up being better to pass qualifiers to `subscribe`;
      # however it feels premature to make this decision since it'll lead
      # to a large increase in complexity to add at this point.
      def mutator(name, qualify: [], &block)
        @mutations[name] = {
          fn: block,
          qualifiers: Array.ensure(qualify),
          name: name,
        }
      end

      def mutation(name)
        @mutations.fetch(name)
      end

      def each(&block)
        @mutations.each(&block)
      end
    end
  end
end
