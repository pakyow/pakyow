RSpec.shared_examples :source_operations_creating do
  describe "creating a database" do
    after do
      # Make sure the database is set back up.
      #
      create_database
    end

    context "database does not exist" do
      before do
        drop_database
        expect(database_exists?).to be(false)
      end

      it "creates" do
        Pakyow::CLI.new(
          %w(db:create --adapter=sql --connection=default)
        )

        expect(database_exists?).to be(true)
      end

      it "clears the setup error", focus: true do
        Pakyow::CLI.new(
          %w(db:create --adapter=sql --connection=default)
        )

        expect(Pakyow.setup_error).to be(nil)
      end
    end

    context "database already exists" do
      before do
        create_database
        expect(database_exists?).to be(true)
      end

      it "silently completes" do
        Pakyow::CLI.new(
          %w(db:create --adapter=sql --connection=default)
        )

        expect(database_exists?).to be(true)
      end
    end
  end
end
