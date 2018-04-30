RSpec.describe "defining a database connection" do
  context "connection type is sql" do
    before do
      Pakyow.config.data.connections.sql[:default] = "sqlite::memory"
    end

    include_context "testable app"

    it "creates a container for the connection" do
      expect(Pakyow.data_connections[:sql][:default]).to be_instance_of(Pakyow::Data::Connection)
    end

    it "creates an adapter for the connection" do
      expect(Pakyow.data_connections[:sql][:default].adapter).to be_instance_of(Pakyow::Data::Adapters::Sql)
    end
  end
end
