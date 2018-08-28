RSpec.describe "isolated component class" do
  include_examples "testable app"

  it "creates an isolated component class for the app" do
    expect(app.isolated(:Component)).to_not be(nil)
  end
end
