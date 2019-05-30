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
            # Validate that each source connection exists.
            #
            state(:source).each do |source|
              Pakyow.connection(source.adapter, source.connection)
            end

            @data = Data::Lookup.new(
              app: self,
              containers: Pakyow.data_connections.values.each_with_object([]) { |connections, containers|
                connections.values.each do |connection|
                  containers << Container.new(
                    connection: connection,
                    sources: state(:source).select { |source|
                      connection.name == source.connection && connection.type == source.adapter
                    },
                    objects: state(:object)
                  )
                end
              }.tap do |containers|
                containers.each do |container|
                  container.finalize!(containers - [container])
                end
              end,
              subscribers: Subscribers.new(
                self,
                Pakyow.config.data.subscriptions.adapter,
                Pakyow.config.data.subscriptions.adapter_settings
              )
            )
          end

          before :shutdown do
            if instance_variable_defined?(:@data)
              @data.subscribers.shutdown
            end
          end
        end
      end
    end
  end
end
