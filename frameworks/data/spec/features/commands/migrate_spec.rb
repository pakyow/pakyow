require "pakyow/cli"

RSpec.describe "cli: db:migrate" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "db:migrate"
  }

  describe "help" do
    it "is helpful" do
      cached_expectation "commands/migrate/help" do
        run_command(command, help: true, project: true)
      end
    end
  end

  describe "running" do
    let(:migrator) {
      instance_double(Pakyow::Data::Migrator, migrate!: nil, disconnect!: nil)
    }

    let(:adapter) {
      :test_adapter
    }

    let(:connection) {
      :test_connection
    }

    before do
      allow(Pakyow::Data::Migrator).to receive(:connect).and_return(migrator)
    end

    it "sets up the environment" do
      expect(Pakyow).to receive(:setup).with(env: :test)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "connects with the given adapter and connection" do
      expect(Pakyow::Data::Migrator).to receive(:connect).with(
        adapter: adapter, connection: connection
      ).and_return(migrator)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "migrates the database" do
      expect(migrator).to receive(:migrate!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "disconnects" do
      expect(migrator).to receive(:disconnect!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end
  end
end
