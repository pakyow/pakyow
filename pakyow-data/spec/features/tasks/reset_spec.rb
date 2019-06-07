require "rake"

RSpec.describe "resetting a connection" do
  before do
    Pakyow.after "configure" do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "cli" do
    let :project_context do
      true
    end
  end

  include_context "app"

  let :task_double do
    double(:task, invoke: nil)
  end

  it "invokes db:drop, db:bootstrap" do
    task_drop = double(:task_drop)
    task_bootstrap = double(:task_bootstrap)

    expect(Rake::Task).to receive(:[]).with("db:drop").and_return(
      task_drop
    )

    expect(Rake::Task).to receive(:[]).with("db:bootstrap").and_return(
      task_bootstrap
    )

    expect(task_drop).to receive(:invoke).with("sql", "default")
    expect(task_bootstrap).to receive(:invoke).with("sql", "default")

    Pakyow::CLI.new(
      %w(db:reset --adapter=sql --connection=default)
    )
  end

  it "tells the user what it's doing" do
    expect(Rake::Task).to receive(:[]).with("db:drop").and_return(
      task_double
    )

    expect(Rake::Task).to receive(:[]).with("db:bootstrap").and_return(
      task_double
    )

    logger = double(:logger)
    allow(Pakyow).to receive(:logger).and_return(logger)
    expect(logger).to receive(:info).with("[db:reset] running: db:drop")
    expect(logger).to receive(:info).with("[db:reset] running: db:bootstrap")

    Pakyow::CLI.new(
      %w(db:reset --adapter=sql --connection=default)
    )
  end
end
