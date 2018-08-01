RSpec.describe "data prelaunch tasks" do
  include_context "testable app"

  let :app_definition do

    Proc.new do
      instance_exec(&$data_app_boilerplate)

      Pakyow.config.data.connections.sql[:default] = "postgres://localhost/pakyow-test"
      Pakyow.config.data.connections.sql[:another] = "postgres://localhost/pakyow-test2"
      Pakyow.config.data.connections.sql[:memory] = "sqlite::memory"
    end
  end

  it "registers a prelaunch task for each migratable connection" do
    expect(Pakyow.config.tasks.prelaunch).to include([:"db:migrate", { adapter: :sql, connection: :default }])
    expect(Pakyow.config.tasks.prelaunch).to include([:"db:migrate", { adapter: :sql, connection: :another }])
  end

  it "does not register in-memory connections" do
    expect(Pakyow.config.tasks.prelaunch).not_to include([:"db:migrate", { adapter: :sql, connection: :memory }])
  end
end
