require "pakyow/server"

RSpec.describe Pakyow::Server do
  let(:subject) {
    described_class.new(context, endpoint: endpoint, protocol: protocol, scheme: scheme)
  }

  let(:context) {
    Proc.new {}
  }

  let(:endpoint) {
    instance_double(Async::HTTP::Endpoint, accept: nil)
  }

  let(:protocol) {
    Async::HTTP::Protocol::HTTP1
  }

  let(:scheme) {
    "http"
  }

  it "is an Async::HTTP::Server" do
    expect(subject.class.ancestors).to include(Async::HTTP::Server)
  end

  describe "::run" do
    it "initializes" do
      expect(described_class).to receive(:new).with(context, endpoint: endpoint, protocol: protocol, scheme: scheme).and_call_original

      ignore_warnings do
        described_class.run(context, endpoint: endpoint, protocol: protocol, scheme: scheme)
      end
    end

    it "runs the instance" do
      instance = instance_double(described_class)
      expect(instance).to receive(:run)
      expect(described_class).to receive(:new).with(context, endpoint: endpoint, protocol: protocol, scheme: scheme).and_return(instance)

      ignore_warnings do
        described_class.run(context, endpoint: endpoint, protocol: protocol, scheme: scheme)
      end
    end
  end
end
