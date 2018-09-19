RSpec.describe "included helpers" do
  include_examples "testable app"

  class Isolatable
  end

  let :app_definition do
    Proc.new {
      isolate Isolatable
      include_helpers :active, :Isolatable
    }
  end

  it "exposes included helpers based on their context" do
    expect(app.__included_helpers[:active]).to include(:Isolatable)
  end
end
