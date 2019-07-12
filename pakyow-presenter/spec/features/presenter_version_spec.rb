RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("618cc6f5b20cb7948121e602121410aab390050e")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("a0fa51ba0b2bfebe0df7b2587eb33935b054159f")
  end
end
