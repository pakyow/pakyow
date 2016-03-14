module Pakyow
  module Presenter
    class ViewContext
      MSG_NONCOMPONENT = 'Cannot subscribe a non-component view'

      # Mutates a view with a registered mutator.
      #
      # @api public
      def mutate(mutator, data: nil, with: nil)
        Pakyow::UI::Mutator.instance.mutate(mutator, self, data || with || [])
      end

      # Subscribes a view and sets the `data-channel` attribute.
      #
      # @api public
      def subscribe(qualifications = {})
        fail ArgumentError, MSG_NONCOMPONENT unless component?

        channel = Pakyow::UI::ChannelBuilder.build(
          component: component_name,
          qualifications: qualifications
        )

        context.socket.subscribe(channel)
        attrs.send(:'data-channel=', channel)
        self
      end
    end
  end
end
