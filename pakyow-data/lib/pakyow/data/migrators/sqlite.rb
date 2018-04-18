# frozen_string_literal: true

require "pakyow/data/migrator"

module Pakyow
  module Data
    class SQLiteMigrator < Migrator
      migrates :sqlite

      def create!
        # intentionally empty; automatically created on connect
      end

      def drop!
        if File.exist?(@connection_opts[:path])
          FileUtils.rm(@connection_opts[:path])
        end
      end
    end
  end
end
