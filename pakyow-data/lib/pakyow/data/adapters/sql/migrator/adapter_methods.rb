# frozen_string_literal: true

module Pakyow
  module Data
    module Adapters
      class Sql
        class Migrator
          module AdapterMethods
            module Mysql
              def create!
                handle_error do
                  global_connection.adapter.connection.run("CREATE DATABASE `#{@connection.opts[:path]}`")
                end
              end

              def drop!
                handle_error do
                  global_connection.adapter.connection.run("DROP DATABASE `#{@connection.opts[:path]}`")
                end
              end

              private

              def create_global_connection
                global_connection_opts = @connection.opts.dup
                global_connection_opts.delete(:path)
                Connection.new(opts: global_connection_opts, type: :sql, name: :global)
              end
            end

            module Postgres
              def create!
                handle_error do
                  global_connection.adapter.connection.run("CREATE DATABASE \"#{@connection.opts[:path]}\"")
                end
              end

              def drop!
                handle_error do
                  global_connection.adapter.connection.run <<~SQL
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

                  global_connection.adapter.connection.run("DROP DATABASE \"#{@connection.opts[:path]}\"")
                end
              end

              private

              def create_global_connection
                global_connection_opts = @connection.opts.dup
                global_connection_opts[:path] = "template1"
                Connection.new(opts: global_connection_opts, type: :sql, name: :global)
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
            end
          end
        end
      end
    end
  end
end
