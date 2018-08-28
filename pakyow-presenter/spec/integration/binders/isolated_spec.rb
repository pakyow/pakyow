RSpec.describe "isolated binder class" do
  include_examples "testable app"

  it "creates an isolated binder class for the app" do
    expect(app.isolated(:Binder)).to_not be(nil)
  end
end
