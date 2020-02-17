RSpec.describe Pakyow::Processes::Proxy do
  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
      described_class, { solution: "do not use" }
    )

    described_class.new(port: 3000, host: "localhost", proxy_port: 3001)
  end
end
