RSpec.describe "data helpers" do
  include_examples "testable app"

  it "registers Data::Helpers as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Data::Helpers)
  end
end
