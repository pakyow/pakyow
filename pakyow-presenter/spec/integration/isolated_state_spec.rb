RSpec.describe "isolated state" do
  include_context "app"

  it "creates an isolated binder class for the app" do
    expect(app.isolated(:Binder)).to_not be(nil)
  end

  it "creates an isolated component class for the app" do
    expect(app.isolated(:Component)).to_not be(nil)
  end

  it "creates an isolated presenter class for the app" do
    expect(app.isolated(:Presenter)).to_not be(nil)
  end

  it "creates an isolated component renderer class for the app" do
    expect(app.isolated(:ComponentRenderer)).to_not be(nil)
  end

  it "creates an isolated view renderer class for the app" do
    expect(app.isolated(:ViewRenderer)).to_not be(nil)
  end
end
