# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/data/container"
require "pakyow/data/lookup"
require "pakyow/data/subscribers"

module Pakyow
  module Data
    module Behavior
      module Lookup
        extend Support::Extension

        # Data container object.
        #
        attr_reader :data

        apply_extension do
          after :initialize do
            @data = Data::Lookup.new(
              containers: Pakyow.data_connections.values.each_with_object([]) { |connections, containers|
                connections.values.each do |connection|
                  containers << Container.new(
                    connection: connection,
                    sources: state_for(:source).select { |source|
                      connection.name == source.connection && connection.type == source.adapter
                    },
                    objects: state_for(:object)
                  )
                end
              },
              subscribers: Subscribers.new(
                self,
                Pakyow.config.data.subscriptions.adapter,
                Pakyow.config.data.subscriptions.adapter_settings.to_h
              )
            )
          end
        end
      end
    end
  end
end
