# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/releasable"

require_relative "../errors"

module Pakyow
  module Behavior
    # Provides frameworks a way to define alpha and beta behavior that's only loaded into a project
    # when the end-user explicitly opts in. Internally, this lets us safely ship features that are
    # under ongoing development or completed features that may not be production-ready.
    #
    module ReleaseChannels
      extend Support::Extension

      include_dependency Support::Releasable

      apply_extension do
        release_channel :alpha, risk: 20
        release_channel :beta, risk: 10

        after "configure" do
          self.release_channel = config.channel
        rescue Support::Releasable::UnknownReleaseChannel => error
          raise UnknownReleaseChannel.build(error, context: self, channel: config.channel)
        end
      end
    end
  end
end
