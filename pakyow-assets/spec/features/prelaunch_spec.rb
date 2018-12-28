RSpec.describe "assets prelaunch tasks" do
  include_context "app"

  it "registers assets:precompile on the app" do
    expect(Pakyow.apps.first.config.tasks.prelaunch).to include("assets:precompile")
  end
end
