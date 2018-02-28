require_relative "shared_examples/associations"
require_relative "shared_examples/commands"
require_relative "shared_examples/connection"
require_relative "shared_examples/queries"
require_relative "shared_examples/qualifications"
require_relative "shared_examples/results"
require_relative "shared_examples/schema"
require_relative "shared_examples/setup"

RSpec.describe "mysql model" do
  include_examples :model_associations
  include_examples :model_commands
  include_examples :model_connection
  include_examples :model_queries
  include_examples :model_qualifications
  include_examples :model_results
  include_examples :model_schema
  include_examples :model_setup

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
