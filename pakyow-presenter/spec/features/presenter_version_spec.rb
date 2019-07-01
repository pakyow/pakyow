RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("437554d44c1883ead7371b62264ebc582eb1f252")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("1546710315ac61fddded0fda5a3d70a2623fa5cd")
  end
end
