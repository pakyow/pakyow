RSpec.describe "logging in the data layer" do
  before do
    Pakyow.config.data.connections.sql[:default] = "sqlite://"
    Pakyow.config.data.logging = logging_enabled
  end

  include_context "testable app"

  context "logging is enabled" do
    let :logging_enabled do
      true
    end

    it "configures the logger" do
      expect(Pakyow.database_containers[:sql][:default].gateways[:default].logger).to be(Pakyow.logger)
    end
  end

  context "logging is disabled" do
    let :logging_enabled do
      false
    end

    it "configures the logger" do
      expect(Pakyow.database_containers[:sql][:default].gateways[:default].logger).to be(nil)
    end
  end
end
