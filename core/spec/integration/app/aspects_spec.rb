RSpec.describe "application aspects" do
  include_context "app"

  it "includes operations" do
    expect(Pakyow.app(:test).config.aspects).to include(:operations)
  end
end
