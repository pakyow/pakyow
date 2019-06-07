# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Environment
    module Data
      module AutoMigrate
        extend Support::Extension

        apply_extension do
          after "boot" do
            if Pakyow.config.data.auto_migrate || Pakyow.config.data.auto_migrate_always.any?
              require "pakyow/data/migrator"

              @data_connections.values.flat_map(&:values)
                .select(&:connected?)
                .select(&:auto_migrate?)
                .select { |connection|
                  Pakyow.config.data.auto_migrate || Pakyow.config.data.auto_migrate_always.include?(connection.name)
                }.each do |auto_migratable_connection|
                migrator = Pakyow::Data::Migrator.new(auto_migratable_connection)
                migrator.auto_migrate!
              end
            end
          end
        end
      end
    end
  end
end
