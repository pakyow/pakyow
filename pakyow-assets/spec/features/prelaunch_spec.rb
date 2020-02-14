RSpec.describe "assets prelaunch commands" do
  include_context "app"

  it "registers assets:precompile on the app" do
    expect(Pakyow.apps.first.config.commands.prelaunch).to include("assets:precompile")
  end
end
