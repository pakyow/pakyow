require "pakyow/runnable/service"

RSpec.describe Pakyow::Runnable::Service do
  let(:service) {
    described_class.make(:test)
  }

  let(:instance) {
    service.new(**options)
  }

  let(:options) {
    {}
  }

  describe "options" do
    let(:options) {
      { foo: 'bar' }
    }

    it "exposes options" do
      expect(instance.options).to eq(options)
    end
  end

  describe "#run" do
    it "performs" do
      expect(instance).to receive(:perform)

      instance.run
    end
  end

  describe "#stop" do
    before do
      instance.run
    end

    it "shuts down" do
      expect(instance).to receive(:shutdown)

      instance.stop
    end

    it "causes the service to appear stopped" do
      expect {
        instance.stop
      }.to change {
        instance.stopped?
      }.from(false).to(true)
    end

    context "service is already stopped" do
      before do
        instance.stop
      end

      it "does not shut down" do
        expect(instance).not_to receive(:shutdown)

        instance.stop
      end
    end
  end

  describe "#stopped?" do
    it "is false by default" do
      expect(instance.stopped?).to eq(false)
    end

    context "service is stopped" do
      before do
        instance.stop
      end

      it "is true" do
        expect(instance.stopped?).to eq(true)
      end
    end
  end

  describe "#limit" do
    it "is nil" do
      expect(instance.limit).to be(nil)
    end
  end

  describe "#count" do
    it "is 1" do
      expect(instance.count).to eq(1)
    end
  end

  describe "#strategy" do
    it "is nil" do
      expect(instance.strategy).to eq(nil)
    end
  end

  describe "#perform" do
    it "can be called" do
      expect {
        instance.perform
      }.to_not raise_error
    end
  end

  describe "#shutdown" do
    it "can be called" do
      expect {
        instance.shutdown
      }.to_not raise_error
    end
  end

  describe "overriding functionality in subclasses" do
    describe "limit" do
      let(:service) {
        described_class.make(:test) {
          def limit
            42
          end
        }
      }

      it "can define its own limit" do
        expect(instance.limit).to eq(42)
      end
    end

    describe "count" do
      let(:service) {
        described_class.make(:test) {
          def count
            42
          end
        }
      }

      it "can define its own count" do
        expect(instance.count).to eq(42)
      end
    end

    describe "strategy" do
      let(:service) {
        described_class.make(:test) {
          def strategy
            :threaded
          end
        }
      }

      it "can define its own strategy" do
        expect(instance.strategy).to eq(:threaded)
      end
    end
  end
end
