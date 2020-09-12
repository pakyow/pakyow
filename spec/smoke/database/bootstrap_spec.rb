require "smoke_helper"
require_relative "../../helpers/database_helpers"

RSpec.describe "bootstrapping a database", :repeatable, smoke: true do
  include DatabaseHelpers

  before do
    local = self

    project_path.join("config/environment.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.configure :development do
          config.data.connections.sql[:default] = "#{local.connection_string}"
        end
      SOURCE
    end

    project_path.join("config/application.rb").open("w+") do |file|
      file.write <<~SOURCE
        Pakyow.app :smoke_test do
          configure do
            config.assets.externals.fetch = false
          end

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

    # Drop it so we have something to bootstrap.
    #
    cli_run "db:drop"
  end

  it "creates the database" do
    cli_run "db:bootstrap"

    expect(sql_database_exists?(connection_string)).to be(true)
  end

  it "migrates the database" do
    cli_run "db:bootstrap"

    expect(tables).to include(:posts)
  end

  context "specifying the adapter" do
    it "creates the database" do
      cli_run "db:bootstrap --adapter sql"

      expect(sql_database_exists?(connection_string)).to be(true)
    end

    it "migrates the database" do
      cli_run "db:bootstrap --adapter sql"

      expect(tables).to include(:posts)
    end
  end

  context "specifying the connection" do
    it "creates the database" do
      cli_run "db:bootstrap --connection default"

      expect(sql_database_exists?(connection_string)).to be(true)
    end

    it "migrates the database" do
      cli_run "db:bootstrap --connection default"

      expect(tables).to include(:posts)
    end
  end

  context "specifying the adapter and connection" do
    it "creates the database" do
      cli_run "db:bootstrap --adapter sql --connection default"

      expect(sql_database_exists?(connection_string)).to be(true)
    end

    it "migrates the database" do
      cli_run "db:bootstrap --adapter sql --connection default"

      expect(tables).to include(:posts)
    end
  end
end
