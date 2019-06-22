RSpec.describe "setting the data subscription version" do
  include_context "app"

  it "sets it to the app version" do
    expect(Pakyow.apps.first.config.data.subscriptions.version).to eq("eba7f939f07bd365141ea0de8474915e38b5fe6f")
  end
end
