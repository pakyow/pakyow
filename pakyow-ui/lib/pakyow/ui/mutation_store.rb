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

      def register(mutate_context, view, mutable_data, qualifications, session)
        @registry.register(
          mutable_data.scope,

          view_scope: view.scoped_as,
          mutation: mutate_context.mutation[:name],
          qualifiers: mutate_context.mutation[:qualifiers],
          qualifications: qualifications,
          query_name: mutable_data.query_name,
          query_args: mutable_data.query_args,
          session: session.to_hash,
          socket_key: mutate_context.view.context.socket_digest(mutate_context.view.context.socket_connection_id)
        )
      end

      def unregister(socket_key)
        @registry.unregister(socket_key)
      end

      def mutations(scope)
        @registry.mutations(scope) || []
      end
    end
  end
end

Pakyow::Realtime::Websocket.on :leave do
  Pakyow::UI::MutationStore.instance.unregister(socket_digest(socket_connection_id))
end
