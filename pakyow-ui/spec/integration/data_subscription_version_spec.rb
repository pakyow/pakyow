RSpec.describe "setting the data subscription version" do
  include_context "app"

  it "sets it to the app version" do
    expect(Pakyow.apps.first.config.data.subscriptions.version).to eq("8c7cc1316eb9ace6dc7d53a1b37130cbf26a610a")
  end
end
