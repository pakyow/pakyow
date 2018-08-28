RSpec.describe "isolated presenter class" do
  include_examples "testable app"

  it "creates an isolated presenter class for the app" do
    expect(app.isolated(:Presenter)).to_not be(nil)
  end
end
