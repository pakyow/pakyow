# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        class Migrator
          # @api private
          module AdapterMethods
            module Mysql
              def create!
                handle_error do
                  @connection.adapter.connection.run("CREATE DATABASE `#{database}`")
                end
              end

              def drop!
                handle_error do
                  @connection.adapter.connection.run("DROP DATABASE `#{database}`")
                end
              end

              def self.globalize_connection_opts!(connection_opts)
                connection_opts[:initial] = Sql.build_opts(path: connection_opts[:path])
                connection_opts[:path] = nil
              end

              private def database
                if @connection.opts.key?(:initial)
                  @connection.opts[:initial][:path]
                else
                  @connection.opts[:path]
                end
              end
            end

            module Postgres
              def create!
                handle_error do
                  @connection.adapter.connection.run("CREATE DATABASE \"#{database}\"")
                end
              end

              def drop!
                handle_error do
                  @connection.adapter.connection.run <<~SQL
                    SELECT
                    pg_terminate_backend(pid)
                    FROM
                    pg_stat_activity
                    WHERE
                    -- don't kill my own connection!
                    pid <> pg_backend_pid()
                    -- don't kill the connections to other databases
                    AND datname = '#{@connection.opts[:path]}';
                  SQL

                  @connection.adapter.connection.run("DROP DATABASE \"#{database}\"")
                end
              end

              def self.globalize_connection_opts!(connection_opts)
                connection_opts[:initial] = Sql.build_opts(path: connection_opts[:path])
                connection_opts[:path] = "template1"
              end

              private def database
                if @connection.opts.key?(:initial)
                  @connection.opts[:initial][:path]
                else
                  @connection.opts[:path]
                end
              end
            end

            module Sqlite
              def create!
                # intentionally empty; automatically created on connect
              end

              def drop!
                if File.exist?(@connection.opts[:path])
                  FileUtils.rm(@connection.opts[:path])
                end
              end

              def self.globalize_connection_opts!(connection_opts)
                # nothing to do here
              end
            end
          end
        end
      end
    end
  end
end
