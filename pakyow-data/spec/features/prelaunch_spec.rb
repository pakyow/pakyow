RSpec.describe "data prelaunch tasks" do
  before do
    Pakyow.configure do
      Pakyow.config.data.connections.sql[:default] = ENV["DATABASE_URL__POSTGRES"]
      Pakyow.config.data.connections.sql[:another] = ENV["DATABASE_URL__MYSQL"]
      Pakyow.config.data.connections.sql[:memory] = "sqlite::memory"
    end
  end

  include_context "app"

  it "registers a prelaunch command for each migratable connection" do
    expect(Pakyow.config.commands.prelaunch).to include(["db:migrate", { adapter: :sql, connection: :default }])
    expect(Pakyow.config.commands.prelaunch).to include(["db:migrate", { adapter: :sql, connection: :another }])
  end

  it "does not register in-memory connections" do
    expect(Pakyow.config.commands.prelaunch).not_to include(["db:migrate", { adapter: :sql, connection: :memory }])
  end
end
