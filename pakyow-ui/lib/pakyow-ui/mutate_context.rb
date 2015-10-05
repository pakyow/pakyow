require_relative 'channel_builder'

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
          MutationStore.instance.register(self, data, qualifications)
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

        if working_view.is_a?(Presenter::ViewCollection)
          # NOTE there's a special case here where if the collection is
          # empty we insert an empty element in its place; this makes
          # it possible to know what the data should be applied to when
          # a mutation occurs in the future

          unless working_view.exists?
            # TODO: would rather this be an html comment, but they aren't
            # supported by query selectors; need to finalize how we will
            # handle this particular edge case
            working_view.first.doc.append('<span data-channel="' + channel + '" data-version="empty"></span>')
            return
          end
        end

        working_view.attrs.send(:'data-channel=', channel)
      end
    end
  end
end
