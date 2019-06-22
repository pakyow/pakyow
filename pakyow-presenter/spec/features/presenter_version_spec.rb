RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("8431efad1d4cd50a637ac8a5c0f46887ede156e2")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("8936f8bfd6ca503460532e639ec0adcd820e046e")
  end
end
