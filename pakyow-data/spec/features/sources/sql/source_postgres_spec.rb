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

require_relative "./shared_examples/raw"
require_relative "./shared_examples/table"
require_relative "./shared_examples/transactions"
require_relative "./shared_examples/types"

RSpec.describe "postgres source" do
  include_examples :source_associations
  include_examples :source_commands
  include_examples :source_connection
  include_examples :source_including
  include_examples :source_logging
  include_examples :source_qualifications
  include_examples :source_queries
  include_examples :source_query_default
  include_examples :source_results
  include_examples :source_types

  include_examples :source_sql_raw
  include_examples :source_sql_table
  include_examples :source_sql_transactions
  include_examples :source_sql_types

  let :connection_type do
    :sql
  end

  let :connection_string do
    "postgres://localhost/pakyow-test"
  end

  before :all do
    unless system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-test")
      system "createdb pakyow-test > /dev/null", out: File::NULL, err: File::NULL
      system "psql pakyow-test -c 'CREATE SCHEMA public' > /dev/null", out: File::NULL, err: File::NULL
    end
  end

  describe "postgres-specific types" do
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

    context "type is json" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :attr, :json
          end
        end
      end

      context "value is a hash" do
        it "defines the attribute" do
          json = { "foo" => "bar", "bar" => true, "baz" => 1 }
          expect(data.posts.create(attr: json).one[:attr]).to eq(json)
        end
      end

      context "value is an array" do
        it "defines the attribute" do
          json = ["foo", "bar", true, 1]
          expect(data.posts.create(attr: json).one[:attr]).to eq(json)
        end
      end
    end
  end
end
