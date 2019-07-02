RSpec.describe "presenter version" do
  include_context "app"

  it "builds the presenter version" do
    expect(Pakyow.apps.first.config.presenter.version).to eq("355afd82a350c7d60be0c89c0bb66beb52bcf257")
  end

  it "rebuilds the app version to include the presenter version" do
    expect(Pakyow.apps.first.config.version).to eq("523bcc2df50145e81c76cc3ae5a67ab241c89f5f")
  end
end
