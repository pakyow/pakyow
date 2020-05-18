require "pakyow/process_manager"

RSpec.describe Pakyow::ProcessManager do
  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
      described_class, { solution: "do not use" }
    )

    described_class.new
  end
end
