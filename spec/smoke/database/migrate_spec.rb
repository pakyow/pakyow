require "smoke_helper"
require_relative "../../helpers/database_helpers"

RSpec.describe "migrating a database", smoke: true do
  include DatabaseHelpers

  before do
    local = self

    project_path.join("config/environment.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.configure do
          config.data.connections.sql[:default] = "#{local.connection_string}"
        end
      SOURCE
    end

    project_path.join("config/application.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test do
          source :posts do
            attribute :title
          end
        end
      SOURCE
    end

    ensure_bundled "pg"
  end

  let(:connection_string) {
    ENV["DATABASE_URL__POSTGRES"] = File.join(ENV["POSTGRES_URL"] || "postgres://localhost", "pakyow-test")
  }

  def tables
    connection = Pakyow::Data::Connection.new(opts: Pakyow::Data::Connection.parse_connection_string(connection_string), type: :sql, name: :tables)
    tables = connection.adapter.connection.tables
    connection.disconnect
    tables
  end

  before do
    # Start with a fresh database.
    #
    cli_run "db:drop"
    cli_run "db:create"

    # Finalize to create the migrations.
    #
    cli_run "db:finalize"

    expect(tables).to be_empty
  end

  it "migrates the database" do
    cli_run "db:migrate"

    expect(tables).to include(:posts)
  end

  context "specifying the adapter" do
    it "migrates the database" do
      cli_run "db:migrate --adapter sql"

      expect(tables).to include(:posts)
    end
  end

  context "specifying the connection" do
    it "migrates the database" do
      cli_run "db:migrate --connection default"

      expect(tables).to include(:posts)
    end
  end

  context "specifying the adapter and connection" do
    it "migrates the database" do
      cli_run "db:migrate --adapter sql --connection default"

      expect(tables).to include(:posts)
    end
  end
end
