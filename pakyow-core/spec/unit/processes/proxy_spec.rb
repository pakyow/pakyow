RSpec.describe Pakyow::Processes::Proxy do
  it "is deprecated" do
    expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
      described_class, { solution: "do not use" }
    )

    described_class.new(port: 3000, host: "localhost", proxy_port: 3001)
  end

  describe "::find_local_port" do
    it "is deprecated" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        described_class, :find_local_port, { solution: "use `Pakyow::Support::System::available_port'" }
      )

      described_class.find_local_port
    end

    it "returns an available port" do
      allow(Pakyow::Support::System).to receive(:available_port).and_return(4242)

      expect(described_class.find_local_port).to eq(4242)
    end
  end
end
