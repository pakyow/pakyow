require "rake"

RSpec.describe "bootstrapping a connection" do
  before do
    Pakyow.after :configure do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "cli" do
    let :project_context do
      true
    end
  end

  include_context "testable app"

  let :task_double do
    double(:task, invoke: nil)
  end

  it "invokes db:create, db:migrate" do
    task_create = double(:task_create)
    task_migrate = double(:task_migrate)

    expect(Rake::Task).to receive(:[]).with("db:create").and_return(
      task_create
    )

    expect(Rake::Task).to receive(:[]).with("db:migrate").and_return(
      task_migrate
    )

    expect(task_create).to receive(:invoke).with("sql", "default")
    expect(task_migrate).to receive(:invoke).with("sql", "default")

    Pakyow::CLI.new(
      %w(db:bootstrap --adapter=sql --connection=default)
    )
  end

  it "tells the user what it's doing" do
    expect(Rake::Task).to receive(:[]).with("db:create").and_return(
      task_double
    )

    expect(Rake::Task).to receive(:[]).with("db:migrate").and_return(
      task_double
    )

    logger = double(:logger)
    allow(Pakyow).to receive(:logger).and_return(logger)
    expect(logger).to receive(:info).with("[db:bootstrap] running: db:create")
    expect(logger).to receive(:info).with("[db:bootstrap] running: db:migrate")

    Pakyow::CLI.new(
      %w(db:bootstrap --adapter=sql --connection=default)
    )
  end
end
