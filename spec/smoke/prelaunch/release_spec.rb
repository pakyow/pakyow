require "smoke_helper"

require_relative "../shared/migrate"

RSpec.describe "prelaunching the release phase", :repeatable, smoke: true do
  include_examples "migrate"

  before do
    cli_run "prelaunch:release -e production"
  end
end
