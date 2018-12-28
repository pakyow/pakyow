RSpec.describe "in-memory database" do
  include_context "app"

  let :autorun do
    false
  end

  context "sqlite is available" do
    before do
      require "sqlite3"
      setup_and_run
    end

    it "configures an in-memory database" do
      expect(Pakyow.config.data.connections.sql[:memory]).to eq("sqlite::memory")
    end
  end

  context "sqlite is not available" do
    before do
      hide_const("SQLite3")
      setup_and_run
    end

    it "does not configure an in-memory database" do
      expect(Pakyow.config.data.connections.sql[:memory]).to be(nil)
    end
  end
end
