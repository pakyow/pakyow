# frozen_string_literal: true

require "pakyow/support/deprecator"
require "pakyow/support/extension"

require_relative "../../data/connection"

module Pakyow
  module Behavior
    module Data
      module Connections
        extend Support::Extension

        apply_extension do
          class_state :data_connections, default: {}

          class << self
            # @api private
            def connection(adapter, connection)
              adapter ||= Pakyow.config.data.default_adapter
              connection ||= Pakyow.config.data.default_connection
              unless connection_instance = Pakyow.data_connections.dig(adapter.to_sym, connection.to_sym)
                # TODO: see if this bubbles up to a level the user can see (e.g. specify in the source)
                #   okay, this is used to fetch a connection through the cli... maybe see if we can reuse when finding the connection for a source too
                #
                raise ArgumentError, "`#{connection}' is not a known database connection for the #{adapter} adapter"
              end

              connection_instance
            end
          end

          on "boot", "boot.data.connections" do
            # Disconnect any existing connections (e.g. booted twice for some reason).
            #
            @data_connections.values.flat_map(&:values).each(&:disconnect)

            # Create new connections.
            #
            @data_connections = Pakyow::Data::Connection.adapter_types.each_with_object({}) { |connection_type, connections|
              connections[connection_type] = Pakyow.config.data.connections.public_send(connection_type).each_with_object({}) { |(connection_name, connection_string), adapter_connections|
                extra_options = {}

                unless Pakyow.config.data.silent
                  extra_options[:logger] = Pakyow.logger
                end

                connection = Pakyow::Data::Connection.new(
                  string: connection_string,
                  type: connection_type,
                  name: connection_name,
                  **extra_options
                )

                if connection.failed?
                  raise connection.failure
                else
                  adapter_connections[connection_name] = connection
                end
              }
            }
          end
        end
      end
    end
  end
end
