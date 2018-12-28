RSpec.describe "data helpers" do
  include_context "app"

  it "registers Data::Helpers as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::Data::Helpers)
  end
end
