require "pakyow/cli"

RSpec.describe "cli: db:create" do
  include_context "app"
  include_context "command"

  let(:precompiler_instance) {
    double(:precompiler).as_null_object
  }

  let(:command) {
    "db:create"
  }

  describe "help" do
    it "is helpful" do
      expect(run_command(command, help: true, project: true)).to eq("\e[34;1mCreate a database\e[0m\n\n\e[1mUSAGE\e[0m\n  $ pakyow db:create\n\n\e[1mOPTIONS\e[0m\n  -e, --env=env                \e[33mWhat environment to use\e[0m\n      --adapter=adapter        \e[33mThe database adapter (default: sql)\e[0m\n  -c, --connection=connection  \e[33mThe database connection (default: default)\e[0m\n")
    end
  end

  describe "running" do
    let(:migrator) {
      instance_double(Pakyow::Data::Migrator, create!: nil, disconnect!: nil)
    }

    let(:adapter) {
      :test_adapter
    }

    let(:connection) {
      :test_connection
    }

    before do
      allow(Pakyow::Data::Migrator).to receive(:connect_global).and_return(migrator)
    end

    it "connects globally with the given adapter and connection" do
      expect(Pakyow::Data::Migrator).to receive(:connect_global).with(
        adapter: adapter, connection: connection
      ).and_return(migrator)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "creates the database" do
      expect(migrator).to receive(:create!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end

    it "disconnects" do
      expect(migrator).to receive(:disconnect!)

      run_command(command, adapter: adapter, connection: connection, project: true)
    end
  end
end
