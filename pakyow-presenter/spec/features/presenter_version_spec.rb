RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("df628a7ca80870bb8c943cb895e6fe50ee83f3a5")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("01cfb83ca46a1af1a4b8a73629762cf6b9c74964")
  end
end
