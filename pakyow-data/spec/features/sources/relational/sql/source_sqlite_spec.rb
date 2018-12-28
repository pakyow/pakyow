require_relative "../shared_examples/associations"
require_relative "../shared_examples/commands"
require_relative "../shared_examples/connection"
require_relative "../shared_examples/default_fields"
require_relative "../shared_examples/including"
require_relative "../shared_examples/logging"
require_relative "../shared_examples/qualifications"
require_relative "../shared_examples/queries"
require_relative "../shared_examples/query_default"
require_relative "../shared_examples/results"
require_relative "../shared_examples/types"

require_relative "./shared_examples/migrations"
require_relative "./shared_examples/operations"
require_relative "./shared_examples/raw"
require_relative "./shared_examples/table"
require_relative "./shared_examples/transactions"
require_relative "./shared_examples/types"

RSpec.describe "sqlite source", sqlite: true do
  it_behaves_like :source_associations
  it_behaves_like :source_commands
  it_behaves_like :source_connection
  it_behaves_like :source_default_fields
  it_behaves_like :source_including
  it_behaves_like :source_logging
  it_behaves_like :source_qualifications
  it_behaves_like :source_queries
  it_behaves_like :source_query_default
  it_behaves_like :source_results
  it_behaves_like :source_types

  it_behaves_like :source_sql_migrations, adapter: :sqlite
  it_behaves_like :source_sql_operations
  it_behaves_like :source_sql_raw
  it_behaves_like :source_sql_table
  it_behaves_like :source_sql_transactions
  it_behaves_like :source_sql_types

  let :connection_type do
    :sql
  end

  let :connection_string do
    "sqlite://#{File.expand_path("../test.db", __FILE__)}"
  end

  after :all do
    drop_database
  end

  def database_exists?
    File.exist?(File.expand_path("../test.db", __FILE__))
  end

  def create_database
    FileUtils.touch(File.expand_path("../test.db", __FILE__))
  end

  def drop_database
    FileUtils.rm_f(File.expand_path("../test.db", __FILE__))
  end

  describe "primary id" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, primary_id: false, timestamps: false do
          primary_id
        end
      end
    end

    let :column do
      schema(:posts)[0][1]
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

    it "is an integer" do
      expect(column[:db_type]).to eq("integer")
      expect(column[:type]).to eq(:integer)
    end
  end

  describe "foreign key" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, primary_id: false, timestamps: false do
          primary_id
          has_many :comments
        end

        source :comments, primary_id: false, timestamps: false do
          primary_id
        end
      end
    end

    let :column do
      schema(:comments)[1][1]
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
      expect(column[:db_type]).to eq("bigint")
      expect(column[:type]).to eq(:integer)
    end
  end

  describe "column types" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :column do
      schema(:posts)[0][1]
    end

    let :app_definition do
      context = self

      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, primary_id: false, timestamps: false do
          attribute :test, context.type
        end
      end
    end

    describe "boolean" do
      let :type do
        :boolean
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("boolean")
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
        expect(column[:db_type]).to eq("timestamp")
      end
    end

    describe "decimal" do
      let :type do
        :decimal
      end

      it "is the correct db type" do
        expect(column[:db_type]).to eq("numeric(10, 2)")
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
        expect(column[:db_type]).to eq("integer")
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
        expect(column[:db_type]).to eq("timestamp")
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
        expect(column[:db_type]).to eq("bigint")
      end
    end
  end
end
