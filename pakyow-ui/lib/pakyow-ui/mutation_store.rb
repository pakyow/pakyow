module Pakyow
  module UI
    # Stores mutations that have occurred in the configured registry.
    #
    # @api private
    class MutationStore
      include Singleton

      def initialize
        @registry = Config.ui.registry.instance
      end

      def register(mutate_context, mutable_data, qualifications)
        # TODO: decide how we'll clean these up as clients disconnect
        @registry.register(
          mutable_data.scope,
          mutation: mutate_context.mutation[:name],
          qualifiers: mutate_context.mutation[:qualifiers],
          qualifications: qualifications,
          query_name: mutable_data.query_name,
          query_args: mutable_data.query_args
        )
      end

      def mutations(scope)
        @registry.mutations(scope) || []
      end
    end
  end
end
