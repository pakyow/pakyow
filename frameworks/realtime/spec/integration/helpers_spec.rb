RSpec.describe "realtime helpers" do
  include_context "app"

  it "registers Realtime::Subscriptions as an active helper" do
    expect(app.helpers_for_context(:active)).to include(Pakyow::Application::Helpers::Realtime::Subscriptions)
  end

  it "registers Realtime::Rendering as a passive helper" do
    expect(app.helpers_for_context(:passive)).to include(Pakyow::Application::Helpers::Realtime::Socket)
  end
end
