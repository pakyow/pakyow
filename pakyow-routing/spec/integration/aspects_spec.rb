RSpec.describe "routing aspects" do
  include_examples "testable app"

  it "registers controllers as an aspect" do
    expect(app.config.aspects).to include(:controllers)
  end

  it "registers resources as an aspect" do
    expect(app.config.aspects).to include(:resources)
  end
end
