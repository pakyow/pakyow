RSpec.describe "realtime helpers" do
  include_examples "testable app"

  it "registers Realtime::Helpers::Subscriptions as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Realtime::Helpers::Subscriptions)
  end

  it "registers Realtime::Helpers::Rendering as a passive helper" do
    expect(app.helpers(:passive)).to include(Pakyow::Realtime::Helpers::Socket)
  end
end
