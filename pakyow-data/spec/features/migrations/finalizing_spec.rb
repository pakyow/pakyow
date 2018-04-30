require_relative "shared_examples/finalizing_migrations"

RSpec.describe "finalizing migrations in sqlite" do
  include_examples :finalizing_migrations

  let :connection_string do
    "sqlite::memory"
  end

  let :initial_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :comments do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end
end

RSpec.describe "finalizing migrations in postgres" do
  include_examples :finalizing_migrations

  let :connection_string do
    "postgres://localhost/pakyow-test"
  end

  let :initial_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :comments do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  before do
    if system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-test")
      system "psql pakyow-test -c 'DROP SCHEMA public CASCADE' > /dev/null", out: File::NULL, err: File::NULL
      system "psql pakyow-test -c 'CREATE SCHEMA public' > /dev/null", out: File::NULL, err: File::NULL
    else
      system "createdb pakyow-test > /dev/null", out: File::NULL, err: File::NULL
    end
  end
end

RSpec.describe "finalizing migrations in mysql" do
  include_examples :finalizing_migrations

  let :connection_string do
    "mysql2://localhost/pakyow-test"
  end

  let :initial_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :posts do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  let :finalized_migration_content do
    <<~CONTENT
      Pakyow.migration do
        change do
          create_table :comments do
            primary_key :id
            column :title, String
          end
        end
      end
    CONTENT
  end

  before do
    if system("mysql -e 'use pakyow-test'")
      system "mysql -e 'DROP DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
    end

    system "mysql -e 'CREATE DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
  end
end
