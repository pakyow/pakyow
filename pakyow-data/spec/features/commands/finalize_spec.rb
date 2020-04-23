require "pakyow/cli"

RSpec.describe "cli: db:finalize" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "db:finalize"
  }

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mFinalize a database\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow db:finalize\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mThe environment to run this command under\e[0m\n      --adapter=adapter        \e[33mThe database adapter (default: sql)\e[0m\n  -c, --connection=connection  \e[33mThe database connection (default: default)\e[0m\n")
    end
  end

  describe "running" do
    let(:global_migrator) {
      instance_double(Pakyow::Data::Migrator, create!: nil, drop!: nil, disconnect!: nil)
    }

    let(:migrator) {
      instance_double(Pakyow::Data::Migrator, migrate!: nil, finalize!: nil, disconnect!: nil)
    }

    let(:adapter) {
      :test_adapter
    }

    let(:connection) {
      :test_connection
    }

    before do
      allow(Pakyow::Data::Migrator).to receive(:connect_global).and_return(global_migrator)
      allow(Pakyow::Data::Migrator).to receive(:connect).and_return(migrator)
    end

    it "sets up the environment" do
      expect(Pakyow).to receive(:setup).with(env: :test)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "connects globally with the given adapter, connection, and overrides" do
      expect(Pakyow::Data::Migrator).to receive(:connect_global) do |opts|
        expect(opts[:adapter]).to be(adapter)
        expect(opts[:connection]).to be(connection)
        expect(opts[:connection_overrides][:path].call("some_path")).to eq("some_path-migrator")
      end.and_return(global_migrator)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "migrates the database" do
      expect(migrator).to receive(:migrate!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "finalizes the database" do
      expect(migrator).to receive(:finalize!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "disconnects" do
      expect(migrator).to receive(:disconnect!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "drops the migrator database" do
      expect(global_migrator).to receive(:drop!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "disconnects the migrator database" do
      expect(global_migrator).to receive(:disconnect!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end
  end
end
