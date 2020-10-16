RSpec.describe "isolated state" do
  include_context "app"

  it "creates an isolated object class for the app" do
    expect(app.isolated(:Object)).to_not be(nil)
  end

  it "creates an isolated source class for the app" do
    expect(app.isolated(:Relational)).to_not be(nil)
  end
end
