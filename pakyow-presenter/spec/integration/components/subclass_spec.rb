RSpec.describe "component subclass" do
  include_examples "testable app"

  it "creates a component subclass for the app" do
    expect(app.subclass(:Component)).to_not be(nil)
  end
end
