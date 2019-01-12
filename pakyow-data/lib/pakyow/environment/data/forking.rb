# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Data
      module Forking
        extend Support::Extension

        apply_extension do
          before :fork do
            connections_to_reconnect.each(&:disconnect)
          end

          after :fork do
            connections_to_reconnect.each(&:connect)
          end
        end

        class_methods do
          def connections_to_reconnect
            @data_connections.values.flat_map(&:values).reject { |connection|
              connection.name == :memory
            }
          end
        end
      end
    end
  end
end
