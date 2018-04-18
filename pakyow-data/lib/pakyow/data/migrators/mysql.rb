# frozen_string_literal: true

require "pakyow/data/migrator"

module Pakyow
  module Data
    class MySQLMigrator < Migrator
      migrates :mysql, :mysql2

      def global_connection
        return @global_connection if @global_connection
        global_connection_opts = @connection_opts.dup
        global_connection_opts.delete(:path)
        @global_connection = Sequel.connect(global_connection_opts)
      end

      def create!
        global_connection.run("CREATE DATABASE `#{@connection_opts[:path]}`")
      end

      def drop!
        global_connection.run("DROP DATABASE `#{@connection_opts[:path]}`")
      rescue Sequel::DatabaseError => e
        Pakyow.logger.warn "Failed to drop database `#{@connection_opts[:path]}`: #{e}"
      end
    end
  end
end
