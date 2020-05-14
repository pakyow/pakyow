require "pakyow/runnable/errors"

RSpec.describe Pakyow::Runnable::Restart do
  it "subclasses Interrupt" do
    expect(described_class.ancestors).to include(Interrupt)
  end
end

RSpec.describe Pakyow::Runnable::Terminate do
  it "subclasses Interrupt" do
    expect(described_class.ancestors).to include(Interrupt)
  end
end
