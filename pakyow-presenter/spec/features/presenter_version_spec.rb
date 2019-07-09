RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("e1fdb776667504e03d79b68774820e9f2fab48c8")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("c86c5e90b214717d72fd201a344c8e70bf5fda36")
  end
end
