# frozen_string_literal: true

require "pakyow/support/extension"
require "pakyow/support/serializer"

module Pakyow
  module Data
    module Behavior
      # Persists in-memory subscribers across restarts.
      #
      module Serialization
        extend Support::Extension

        apply_extension do
          before :shutdown do
            if Pakyow.config.data.subscriptions.adapter == :memory && data
              subscriber_serializer.serialize
            end
          end

          after :initialize, priority: :low do
            if Pakyow.config.data.subscriptions.adapter == :memory && data
              subscriber_serializer.deserialize
            end
          end
        end

        private def subscriber_serializer
          Support::Serializer.new(
            data.subscribers.adapter,
            name: "#{config.name}-subscribers",
            path: File.join(
              Pakyow.config.root, "tmp", "state"
            )
          )
        end
      end
    end
  end
end
