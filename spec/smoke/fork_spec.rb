require "smoke_helper"
require_relative "../helpers/database_helpers"

RSpec.describe "disconnecting the database before forking", :repeatable, smoke: true do
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
        Pakyow.app :smoke_test, only: %i[routing data] do
          controller "/" do
            default do
              send data.posts.count.to_s
            end
          end

          controller "/comments" do
            default do
              send data.comments.count.to_s
            end
          end

          source :posts do
            # intentionally empty
          end

          source :comments, connection: :memory do
            attribute :content
          end
        end
      SOURCE
    end

    ensure_bundled "pg"

    if sql_database_exists?(connection_string)
      drop_sql_database(connection_string)
    end

    expect(sql_database_exists?(connection_string)).to be(false)

    cli_run "db:create"

    boot
  end

  let(:connection_string) {
    ENV["DATABASE_URL__POSTGRES"] = File.join(ENV["POSTGRES_URL"] || "postgres://localhost", "pakyow-test")
  }

  it "creates the database" do
    response = http.get("http://localhost:#{port}/")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to eq("0")
  end

  it "maintains auto migrated state in the memory connection" do
    response = http.get("http://localhost:#{port}/comments")

    expect(response.status).to eq(200)
    expect(response.body.to_s).to eq("0")
  end
end
