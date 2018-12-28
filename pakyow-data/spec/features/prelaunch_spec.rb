RSpec.describe "data prelaunch tasks" do
  include_context "app"

  let :app_def do
    Proc.new do
      Pakyow.after :configure do
        Pakyow.config.data.connections.sql[:default] = "postgres://localhost/pakyow-test"
        Pakyow.config.data.connections.sql[:another] = "mysql2://localhost/pakyow-test"
        Pakyow.config.data.connections.sql[:memory] = "sqlite::memory"
      end
    end
  end

  before :all do
    unless system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-test")
      system "createdb pakyow-test > /dev/null", out: File::NULL, err: File::NULL
    end

    unless system("mysql -e 'use pakyow-test'")
      system "mysql -e 'CREATE DATABASE `pakyow-test`'", out: File::NULL, err: File::NULL
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
