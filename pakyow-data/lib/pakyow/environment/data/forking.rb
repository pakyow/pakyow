# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Data
      module Forking
        extend Support::Extension

        apply_extension do
          before :fork do
            @data_connections.values.flat_map(&:values).each do |connection|
              unless connection.name == :memory
                connection.disconnect
              end
            end
          end
        end
      end
    end
  end
end
