require "smoke_helper"

require_relative "../shared/precompile"

RSpec.describe "prelaunching the build phase", :repeatable, smoke: true do
  include_examples "precompile"

  before do
    cli_run "prelaunch:build -e production"
  end
end
