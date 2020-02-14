require "smoke_helper"
require_relative "../../helpers/database_helpers"

RSpec.describe "dropping a database", smoke: true do
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

    ensure_bundled "pg"
  end

  let(:connection_string) {
    ENV["DATABASE_URL__POSTGRES"] = File.join(ENV["POSTGRES_URL"] || "postgres://localhost", "pakyow-test")
  }

  before do
    unless sql_database_exists?(connection_string)
      create_sql_database(connection_string)
    end

    expect(sql_database_exists?(connection_string)).to be(true)
  end

  it "drops the database" do
    cli_run "db:drop"

    expect(sql_database_exists?(connection_string)).to be(false)
  end

  context "specifying the adapter" do
    it "drops the database" do
      cli_run "db:drop --adapter sql"

      expect(sql_database_exists?(connection_string)).to be(false)
    end
  end

  context "specifying the connection" do
    it "drops the database" do
      cli_run "db:drop --connection default"

      expect(sql_database_exists?(connection_string)).to be(false)
    end
  end

  context "specifying the adapter and connection" do
    it "drops the database" do
      cli_run "db:drop --adapter sql --connection default"

      expect(sql_database_exists?(connection_string)).to be(false)
    end
  end

  context "database already exists" do
    it "does not fail" do
      drop_sql_database(connection_string)
      expect(sql_database_exists?(connection_string)).to be(false)
      expect(cli_run("db:drop").success?).to be(true)
    end
  end
end
