require "pakyow/processes/proxy"

RSpec.describe Pakyow::Processes::Proxy::Server do
  before do
    allow(Async::HTTP::Client).to receive(:new)
    allow(Async::HTTP::Endpoint).to receive(:parse)
  end

  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
      described_class, { solution: "do not use" }
    )

    described_class.new(port: 3000, host: "localhost", forwarded: nil)
  end
end
