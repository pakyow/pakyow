require "smoke_helper"
require_relative "../../helpers/database_helpers"

RSpec.describe "finalizing a database", smoke: true do
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

  before do
    cli_run "db:drop"
    cli_run "db:create"
  end

  it "finalizes the database" do
    cli_run "db:finalize"

    project_path.join("database").glob("**/*").any? { |path|
      path.to_s.match?(/database\/migrations\/sql\/default\/(.*)_create_posts\.rb/)
    }
  end

  context "specifying the adapter" do
    it "finalizes the database" do
      cli_run "db:finalize --adapter sql"

      project_path.join("database").glob("**/*").any? { |path|
        path.to_s.match?(/database\/migrations\/sql\/default\/(.*)_create_posts\.rb/)
      }
    end
  end

  context "specifying the connection" do
    it "finalizes the database" do
      cli_run "db:finalize --connection default"

      project_path.join("database").glob("**/*").any? { |path|
        path.to_s.match?(/database\/migrations\/sql\/default\/(.*)_create_posts\.rb/)
      }
    end
  end

  context "specifying the adapter and connection" do
    it "finalizes the database" do
      cli_run "db:finalize --adapter sql --connection default"

      project_path.join("database").glob("**/*").any? { |path|
        path.to_s.match?(/database\/migrations\/sql\/default\/(.*)_create_posts\.rb/)
      }
    end
  end

  context "no changes are required" do
    it "does not create any more migrations" do
      cli_run "db:finalize"

      expect {
        cli_run "db:finalize"
      }.not_to change {
        project_path.join("database").glob("**/*").count
      }
    end
  end
end
