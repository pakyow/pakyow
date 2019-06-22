RSpec.describe "app version" do
  include_context "app"

  it "builds the app version" do
    expect(Pakyow.apps.first.config.version).to eq("da39a3ee5e6b4b0d3255bfef95601890afd80709")
  end
end
