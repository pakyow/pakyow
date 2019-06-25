RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("6a2b697c53e166a35babd9a7ac49e26088c95989")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("3554b668c5ce6941493baf506e4ff7a0e9a795e8")
  end
end
