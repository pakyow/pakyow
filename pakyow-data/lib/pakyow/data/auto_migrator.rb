# frozen_string_literal: true

module Pakyow
  module Data
    class AutoMigrator
      def initialize(connection:, sources:)
        @connection, @sources = connection, sources
      end

      def migrate!
        @sources.each do |source|
          if @connection.needs_migration?(source)
            @connection.auto_migrate!(source)
          end
        end
      end
    end
  end
end
