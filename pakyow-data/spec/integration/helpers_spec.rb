RSpec.describe "data helpers" do
  include_context "app"

  it "registers Data as an active helper" do
    expect(app.helpers(:active)).to include(Pakyow::App::Helpers::Data)
  end
end
