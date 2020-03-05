require_relative "../../helpers/database_helpers"

RSpec.shared_examples "migrate" do
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

    expect(tables).to be_empty
  end

  it "migrates the database" do
    expect(tables).to include(:posts)
  end
end
