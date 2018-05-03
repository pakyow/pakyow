require_relative "../shared_examples/associations"
require_relative "../shared_examples/commands"
require_relative "../shared_examples/connection"
require_relative "../shared_examples/logging"
require_relative "../shared_examples/queries"
require_relative "../shared_examples/qualifications"
require_relative "../shared_examples/results"
require_relative "../shared_examples/schema"

require_relative "./shared_examples/raw"
require_relative "./shared_examples/table"
require_relative "./shared_examples/transactions"

RSpec.describe "mysql source" do
  include_examples :source_associations
  include_examples :source_commands
  include_examples :source_connection
  include_examples :source_logging
  include_examples :source_queries
  include_examples :source_qualifications
  include_examples :source_results
  include_examples :source_schema

  include_examples :source_sql_raw
  include_examples :source_sql_table
  include_examples :source_sql_transactions

  let :connection_type do
    :sql
  end

  let :connection_string do
    "mysql2://localhost/pakyow-test"
  end

  before do
    if system("mysql -e 'use pakyow-test'")
      system "mysql -e 'DROP DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
    end

    system "mysql -e 'CREATE DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
  end

  describe "mysql-specific types" do
    it "needs to be defined"
  end
end
