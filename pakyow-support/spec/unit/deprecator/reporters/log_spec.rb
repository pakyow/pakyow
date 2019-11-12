require "pakyow/support/deprecator/reporters/log"

RSpec.describe Pakyow::Support::Deprecator::Reporters::Log do
  module PakyowWithLogger
    def self.logger; end
  end

  describe "::default" do
    before do
      stub_const "Pakyow", PakyowWithLogger
      allow(Pakyow).to receive(:logger).and_return(logger)
    end

    after do
      if @defined_logger

      end
    end

    let(:logger) {
      double(:logger)
    }

    it "builds an instance with the environment logger" do
      expect(described_class).to receive(:new).with(logger: logger)
      described_class.default
    end

    it "returns an instance of itself" do
      expect(described_class.default).to be_instance_of(described_class)
    end

    it "returns a new instance" do
      expect(described_class.default).not_to be(described_class.default)
    end
  end
end
