RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("ed6c73c00503ae201c01e0ffc42b14a8df473054")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("7f63c5274c46760e956d0e95f7aac3d0eef16456")
  end
end
