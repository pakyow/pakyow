RSpec.shared_examples :source_operations_creating do
  describe "creating a database" do
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
