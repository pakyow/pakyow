# frozen_string_literal: true

module Pakyow
  module Presenter
    # Used by NoOpView to perform mutations in a no-op manner.
    #
    # @api private
    class MockMutationEval
      def initialize(mutation_name, relation_name, view)
        @mutation_name = mutation_name
        @relation_name = relation_name
        @view = view
      end

      # NOTE we don't care about qualifiers here since we're just getting
      # the proper view template; not actually setting it up with data
      def subscribe(*_args)
        channel = Pakyow::UI::ChannelBuilder.build(
          scope: @view.scoped_as,
          mutation: @mutation_name
        )

        @view.attrs.send(:'data-channel=', channel)
      end
    end
  end
end
