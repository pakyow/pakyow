RSpec.describe "defining a database connection" do
  context "connection type is memory" do
    before do
      Pakyow.config.connections.memory[:default] = "memory://test"
    end

    include_context "testable app"

    let :connection_string do
      "memory://test"
    end

    it "creates a container for the connection" do
      expect(Pakyow.database_containers[:memory][:default]).to be_instance_of(ROM::Container)
    end

    it "creates a gateway for the adapter" do
      expect(Pakyow.database_containers[:memory][:default].gateways[:default]).to be_instance_of(ROM::Memory::Gateway)
    end
  end

  context "connection type is sql" do
    before do
      Pakyow.config.connections.sql[:default] = "sqlite://"
    end

    include_context "testable app"

    it "creates a container for the connection" do
      expect(Pakyow.database_containers[:sql][:default]).to be_instance_of(ROM::Container)
    end

    it "creates a gateway for the adapter" do
      expect(Pakyow.database_containers[:sql][:default].gateways[:default]).to be_instance_of(ROM::SQL::Gateway)
    end
  end
end
