RSpec.describe "data helpers" do
  include_context "app"

  it "registers Data as an active helper" do
    expect(app.helpers_for_context(:active)).to include(Pakyow::Application::Helpers::Data)
  end
end
