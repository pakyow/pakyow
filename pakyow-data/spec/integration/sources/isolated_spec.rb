RSpec.describe "isolated source class" do
  include_examples "testable app"

  it "creates an isolated source class for the app" do
    expect(app.isolated(:Source)).to_not be(nil)
  end
end
