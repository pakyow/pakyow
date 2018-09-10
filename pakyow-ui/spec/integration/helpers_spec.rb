RSpec.describe "routing helpers" do
  include_examples "testable app"

  it "registers UI::Helpers as a passive helper" do
    expect(app.helpers(:passive)).to include(Pakyow::UI::Helpers)
  end
end
