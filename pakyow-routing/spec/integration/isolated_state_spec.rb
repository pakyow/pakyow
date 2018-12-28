RSpec.describe "isolated state" do
  include_context "app"

  it "creates an isolated controller class for the app" do
    expect(app.isolated(:Controller)).to_not be(nil)
  end
end
