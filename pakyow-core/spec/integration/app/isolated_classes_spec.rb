RSpec.describe "isolated classes" do
  include_examples "testable app"

  class Isolatable
  end

  let :app_definition do
    Proc.new {
      isolate Isolatable
    }
  end

  it "exposes isolated classes" do
    expect(app.__isolated_classes).to include(Isolatable)
  end
end
