RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("6e11f50c91c9bec8252b702c5b08af565f47a280")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("73bddc6a31e737410d88725d61d5d580fa56aac0")
  end
end
