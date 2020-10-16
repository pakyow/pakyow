# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    module Data
      # Configures an in-memory sqlite database.
      #
      module MemoryDB
        extend Support::Extension

        apply_extension do
          after "configure" do
            if defined?(SQLite3)
              config.data.connections.sql[:memory] = "sqlite::memory"
            end
          end
        end
      end
    end
  end
end
