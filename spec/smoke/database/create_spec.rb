require "smoke_helper"
require_relative "../../helpers/database_helpers"

RSpec.describe "creating a database", smoke: true do
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
        end
      SOURCE
    end

    ensure_bundled "pg"
  end

  let(:connection_string) {
    ENV["DATABASE_URL__POSTGRES"] = File.join(ENV["POSTGRES_URL"] || "postgres://localhost", "pakyow-test")
  }

  before do
    if sql_database_exists?(connection_string)
      drop_sql_database(connection_string)
    end

    expect(sql_database_exists?(connection_string)).to be(false)
  end

  it "creates the database" do
    cli_run "db:create"

    expect(sql_database_exists?(connection_string)).to be(true)
  end

  context "specifying the adapter" do
    it "creates the database" do
      cli_run "db:create --adapter sql"

      expect(sql_database_exists?(connection_string)).to be(true)
    end
  end

  context "specifying the connection" do
    it "creates the database" do
      cli_run "db:create --connection default"

      expect(sql_database_exists?(connection_string)).to be(true)
    end
  end

  context "specifying the adapter and connection" do
    it "creates the database" do
      cli_run "db:create --adapter sql --connection default"

      expect(sql_database_exists?(connection_string)).to be(true)
    end
  end

  context "database already exists" do
    it "does not fail" do
      create_sql_database(connection_string)
      expect(sql_database_exists?(connection_string)).to be(true)
      expect(cli_run("db:create").success?).to be(true)
    end
  end
end
