require "smoke_helper"

require_relative "../shared/migrate"

RSpec.describe "migrating a database", :repeatable, smoke: true do
  include_examples "migrate"

  before do
    run
  end

  def run
    cli_run "db:migrate"
  end

  context "specifying the adapter" do
    def run
      cli_run "db:migrate --adapter sql"
    end

    it "migrates the database" do
      expect(tables).to include(:posts)
    end
  end

  context "specifying the connection" do
    def run
      cli_run "db:migrate --connection default"
    end

    it "migrates the database" do
      expect(tables).to include(:posts)
    end
  end

  context "specifying the adapter and connection" do
    def run
      cli_run "db:migrate --adapter sql --connection default"
    end

    it "migrates the database" do
      expect(tables).to include(:posts)
    end
  end
end
