RSpec.shared_examples :source_operations_dropping do
  describe "dropping a database" do
    context "database exists" do
      before do
        create_database
        expect(database_exists?).to be(true)
      end

      it "drops the database" do
        Pakyow::CLI.new(
          %w(db:drop --adapter=sql --connection=default)
        )

        expect(database_exists?).to be(false)
      end
    end

    context "database does not exist" do
      before do
        drop_database
        expect(database_exists?).to be(false)
      end

      it "silently completes" do
        Pakyow::CLI.new(
          %w(db:drop --adapter=sql --connection=default)
        )

        expect(database_exists?).to be(false)
      end
    end
  end
end
