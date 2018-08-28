RSpec.describe "isolated object class" do
  include_examples "testable app"

  it "creates an isolated object class for the app" do
    expect(app.isolated(:Object)).to_not be(nil)
  end
end
