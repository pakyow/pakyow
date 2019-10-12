RSpec.describe "data prelaunch tasks" do
  include_context "app"

  let :app_def do
    Proc.new do
      Pakyow.after "configure" do
        Pakyow.config.data.connections.sql[:default] = ENV["DATABASE_URL__POSTGRES"]
        Pakyow.config.data.connections.sql[:another] = ENV["DATABASE_URL__MYSQL"]
        Pakyow.config.data.connections.sql[:memory] = "sqlite::memory"
      end
    end
  end

  it "registers a prelaunch task for each migratable connection" do
    expect(Pakyow.config.tasks.prelaunch).to include(["db:migrate", { adapter: :sql, connection: :default }])
    expect(Pakyow.config.tasks.prelaunch).to include(["db:migrate", { adapter: :sql, connection: :another }])
  end

  it "does not register in-memory connections" do
    expect(Pakyow.config.tasks.prelaunch).not_to include(["db:migrate", { adapter: :sql, connection: :memory }])
  end
end
