# frozen_string_literal: true

require "pakyow/data/migrator"

module Pakyow
  module Data
    class MySQLMigrator < Migrator
      migrates :mysql, :mysql2

      def create!
        global_connection.adapter.connection.run("CREATE DATABASE `#{@connection_opts[:path]}`")
      end

      def drop!
        global_connection.adapter.connection.run("DROP DATABASE `#{@connection_opts[:path]}`")
      rescue Sequel::DatabaseError => e
        Pakyow.logger.warn "Failed to drop database `#{@connection_opts[:path]}`: #{e}"
      end

      private

      def create_global_connection
        global_connection_opts = @connection_opts.dup
        global_connection_opts.delete(:path)
        Connection.new(opts: global_connection_opts, type: :sql, name: :global)
      end
    end
  end
end
