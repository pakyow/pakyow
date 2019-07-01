RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("d1ff9d9482d772be10d07c50e5e2aab23a31eadf")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("94e7806212ffeb1d8cee9f19ab32bbbb3ef2d459")
  end
end
