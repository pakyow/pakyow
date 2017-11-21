# frozen_string_literal: true

require_relative "channel_builder"

module Pakyow
  module UI
    # Provides helper methods to perform in context of a mutation. For example:
    #
    # view.scope(:foo).mutate(:bar).subscribe
    #
    # In the above example `mutate` returns a MutateContext object on which
    # `subscribe` is called.
    #
    # @api public
    class MutateContext
      attr_reader :mutation, :view, :data

      # Creates a new context. Intended to be created by a Mutator.
      #
      # @api private
      def initialize(mutation, view, data)
        @mutation = mutation
        @view     = view
        @data     = data
      end

      # Subscribes a mutation with optional qualifications. Qualifications are
      # used to control the scope of future mutations. For example:
      #
      # view.scope(:foo).mutate(:bar).subscribe(user_id: 1)
      #
      # In the above example, a subscription is created qualified by `user_id`.
      # Only mutations occuring with the same qualifications will cause the
      # mutation to be performed again, triggering a view refresh.
      #
      # ui.mutated(:foo, user_id: 1)
      #
      # @api public
      def subscribe(qualifications = {})
        if data.is_a?(MutableData)
          MutationStore.instance.register(self, view, data, qualifications, view.context.request.session)
        end

        channel = ChannelBuilder.build(
          scope: view.scoped_as,
          mutation: mutation[:name],
          qualifiers: mutation[:qualifiers],
          data: data,
          qualifications: qualifications
        )

        # subscribe to the channel
        view.context.socket.subscribe(channel)

        # handle setting the channel on the view
        if view.is_a?(Presenter::ViewContext)
          working_view = view.instance_variable_get(:@view)
        else
          working_view = view
        end

        working_view.attrs.send(:'data-channel=', channel)
      end
    end
  end
end
