require_relative "../shared_examples/associations"
require_relative "../shared_examples/commands"
require_relative "../shared_examples/connection"
require_relative "../shared_examples/including"
require_relative "../shared_examples/logging"
require_relative "../shared_examples/qualifications"
require_relative "../shared_examples/queries"
require_relative "../shared_examples/query_default"
require_relative "../shared_examples/results"
require_relative "../shared_examples/types"

require_relative "./shared_examples/migrations"
require_relative "./shared_examples/raw"
require_relative "./shared_examples/table"
require_relative "./shared_examples/transactions"
require_relative "./shared_examples/types"

RSpec.describe "mysql source" do
  it_behaves_like :source_associations
  it_behaves_like :source_commands
  it_behaves_like :source_connection
  it_behaves_like :source_including
  it_behaves_like :source_logging
  it_behaves_like :source_qualifications
  it_behaves_like :source_queries
  it_behaves_like :source_query_default
  it_behaves_like :source_results
  it_behaves_like :source_types

  it_behaves_like :source_sql_migrations, adapter: :mysql2
  it_behaves_like :source_sql_raw
  it_behaves_like :source_sql_table
  it_behaves_like :source_sql_transactions
  it_behaves_like :source_sql_types

  let :connection_type do
    :sql
  end

  let :connection_string do
    "mysql2://localhost/pakyow-test"
  end

  before :all do
    unless system("mysql -e 'use pakyow-test'")
      system "mysql -e 'CREATE DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
    end
  end

  describe "default primary id" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
        end
      end
    end

    let :column do
      data.posts.source.container.connection.adapter.connection.schema(:posts)[0][1]
    end

    it "is a primary key" do
      expect(column[:primary_key]).to eq(true)
    end

    it "auto increments" do
      expect(column[:auto_increment]).to eq(true)
    end

    it "does not allow null" do
      expect(column[:allow_null]).to eq(false)
    end

    it "has no default" do
      expect(column[:default]).to eq(nil)
    end

    it "is a bignum integer" do
      expect(column[:db_type]).to eq("bigint(20)")
      expect(column[:type]).to eq(:integer)
    end

    context "primary key is a custom type" do
      it "is of the correct type"
    end
  end

  describe "default foreign key" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          has_many :comments
        end

        source :comments do
          primary_id
        end
      end
    end

    let :column do
      data.comments.source.container.connection.adapter.connection.schema(:comments)[1][1]
    end

    it "is not a primary key" do
      expect(column[:primary_key]).to eq(false)
    end

    it "does not auto increment" do
      expect(column[:auto_increment]).to eq(nil)
    end

    it "allows null" do
      expect(column[:allow_null]).to eq(true)
    end

    it "has no default" do
      expect(column[:default]).to eq(nil)
    end

    it "is a bignum integer" do
      expect(column[:db_type]).to eq("bigint(20)")
      expect(column[:type]).to eq(:integer)
    end

    context "primary key for the foreign source is a custom type" do
      it "matches the type"
    end
  end

  describe "column types" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :column do
      data.posts.source.container.connection.adapter.connection.schema(:posts)[0][1]
    end

    let :app_definition do
      context = self

      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          attribute :test, context.type
        end
      end
    end

    describe "boolean" do
      let :type do
        :boolean
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("tinyint(1)")
      end

      it "is the correct type" do
        expect(column[:type]).to eq(:boolean)
      end
    end

    describe "date" do
      let :type do
        :date
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("date")
      end
    end

    describe "datetime" do
      let :type do
        :datetime
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("datetime")
      end
    end

    describe "decimal" do
      let :type do
        :decimal
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("decimal(10,2)")
      end
    end

    describe "float" do
      let :type do
        :float
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("float")
      end
    end

    describe "integer" do
      let :type do
        :integer
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("int(11)")
      end
    end

    describe "string" do
      let :type do
        :string
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("varchar(255)")
      end
    end

    describe "time" do
      let :type do
        :time
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("datetime")
      end
    end

    describe "file" do
      let :type do
        :file
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("blob")
      end
    end

    describe "text" do
      let :type do
        :text
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("text")
      end
    end

    describe "bignum" do
      let :type do
        :bignum
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("bigint(20)")
      end
    end
  end
end
