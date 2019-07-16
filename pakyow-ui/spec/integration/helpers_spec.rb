RSpec.describe "routing helpers" do
  include_context "app"

  it "registers UI as a passive helper" do
    expect(app.helpers(:passive)).to include(Pakyow::Application::Helpers::UI)
  end
end
