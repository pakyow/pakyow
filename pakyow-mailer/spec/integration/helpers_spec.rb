RSpec.describe "mailer helpers" do
  include_context "app"

  it "registers Mailer::Helpers as an active helper" do
    expect(app.helpers_for_context(:active)).to include(Pakyow::Application::Helpers::Mailer)
  end
end
