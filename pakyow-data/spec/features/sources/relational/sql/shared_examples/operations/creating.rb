RSpec.shared_examples :source_operations_creating do
  describe "creating a database" do
    include_context "command"

    before do
      setup
    end

    after do
      # Make sure the database is set back up.
      #
      create_sql_database(connection_string)
    end

    context "database does not exist" do
      before do
        drop_sql_database(connection_string)
        expect(sql_database_exists?(connection_string)).to be(false)
      end

      it "creates" do
        run_command("db:create", adapter: :sql, connection: :default, project: true)

        expect(sql_database_exists?(connection_string)).to be(true)
      end

      it "clears the setup error" do
        run_command("db:create", adapter: :sql, connection: :default, project: true)

        expect(Pakyow.setup_error).to be(nil)
      end
    end

    context "database already exists" do
      before do
        create_sql_database(connection_string)
        expect(sql_database_exists?(connection_string)).to be(true)
      end

      it "silently completes" do
        run_command("db:create", adapter: :sql, connection: :default, project: true)

        expect(sql_database_exists?(connection_string)).to be(true)
      end
    end
  end
end
