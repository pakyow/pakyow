# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../../data/container"
require_relative "../../../data/lookup"
require_relative "../../../data/subscribers"

module Pakyow
  class Application
    module Behavior
      module Data
        module Lookup
          extend Support::Extension

          # Data container object.
          #
          attr_reader :data

          apply_extension do
            after "boot", "initialize.data", priority: :high do
              # Validate that each source connection exists.
              #
              sources.each do |source|
                Pakyow.connection(source.adapter, source.connection)
              end

              subscribers = if is_a?(Plugin)
                # Plugins should use the same subscribers object as their parent app.
                #
                parent.data.subscribers
              else
                Pakyow::Data::Subscribers.new(
                  self,
                  Pakyow.config.data.subscriptions.adapter,
                  Pakyow.config.data.subscriptions.adapter_settings
                )
              end

              containers = Pakyow.data_connections.values.each_with_object([]) { |connections, arr|
                connections.values.each do |connection|
                  arr << Pakyow::Data::Container.new(
                    connection: connection,
                    sources: sources.each.select { |source|
                      connection.name == source.connection && connection.type == source.adapter
                    },
                    objects: objects.each.to_a
                  )
                end
              }

              containers.each do |container|
                container.finalize_associations!(containers - [container])
              end

              containers.each do |container|
                container.finalize_sources!(containers - [container])
              end

              @data = Pakyow::Data::Lookup.new(
                app: self,
                containers: containers,
                subscribers: subscribers
              )
            end

            on "shutdown" do
              if instance_variable_defined?(:@data)
                @data.subscribers.shutdown
              end
            end
          end
        end
      end
    end
  end
end
