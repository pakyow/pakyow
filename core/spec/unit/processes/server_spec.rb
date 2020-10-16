require "pakyow/processes/server"

RSpec.describe Pakyow::Processes::Server do
  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
      described_class, { solution: "do not use" }
    )

    described_class.new(endpoint: nil, protocol: nil, scheme: nil)
  end
end
