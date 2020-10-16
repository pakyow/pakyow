RSpec.shared_examples :source_operations_dropping do
  describe "dropping a database" do
    include_context "command"

    before do
      setup
    end

    after do
      # Make sure the database is set back up.
      #
      create_sql_database(connection_string)
    end

    context "database exists" do
      before do
        create_sql_database(connection_string)
        expect(sql_database_exists?(connection_string)).to be(true)
      end

      it "drops the database" do
        run_command("db:drop", adapter: :sql, connection: :default, project: true)

        expect(sql_database_exists?(connection_string)).to be(false)
      end
    end

    context "database does not exist" do
      before do
        drop_sql_database(connection_string)
        expect(sql_database_exists?(connection_string)).to be(false)
      end

      it "silently completes" do
        run_command("db:drop", adapter: :sql, connection: :default, project: true)

        expect(sql_database_exists?(connection_string)).to be(false)
      end
    end
  end
end
