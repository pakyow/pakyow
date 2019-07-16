RSpec.describe "realtime helpers" do
  include_context "app"

  it "registers Realtime::Subscriptions as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::App::Helpers::Realtime::Subscriptions)
  end

  it "registers Realtime::Rendering as a passive helper" do
    expect(app.helpers(:passive)).to include(Pakyow::App::Helpers::Realtime::Socket)
  end
end
