require "smoke_helper"

require_relative "../shared/precompile"

RSpec.describe "precompiling assets for a path", smoke: true do
  include_examples "precompile"

  before do
    File.open(project_path.join("Gemfile"), "a") do |file|
      file.write("\ngem \"sqlite3\"")
    end

    cli_run "assets:precompile -a smoke_test -e production"
  end

  let :envars do
    {
      "SECRET" => "sekret",
      "DATABASE_URL" => "sqlite://database/production.db"
    }
  end
end
