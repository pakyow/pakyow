require "pakyow/logger/thread_local"

RSpec.describe Pakyow::Logger::ThreadLocal do
  before do
    allow(Pakyow).to receive(:deprecated)
  end

  let(:instance) {
    described_class.new(default)
  }

  let(:default) {
    instance_double(Pakyow::Logger)
  }

  describe "#initialize" do
    context "without passing a value for key" do
      it "is deprecated" do
        expect(Pakyow).to receive(:deprecated).with(
          "default value for `Pakyow::Logger::ThreadLocal' argument `key'",
          solution: "pass value for `key'"
        )

        instance
      end

      it "defaults to :pakyow_logger" do
        instance.set :foo

        expect(instance.thread_localized(:logger_thread_local_pakyow_logger)).to be(:foo)
      end
    end
  end

  describe "#silence" do
    before do
      instance.set(local)
      allow(local).to receive(:dup).and_return(duped)
      allow(duped).to receive(:level=)
    end

    let(:local) {
      instance_double(Pakyow::Logger)
    }

    let(:duped) {
      instance_double(Pakyow::Logger)
    }

    it "yields" do
      expect { |block|
        instance.silence(&block)
      }.to yield_control
    end

    it "sets a copy of the current logger configured at the given level" do
      expect(duped).to receive(:level=).with(:warn)

      instance.silence :warn do
        expect(instance.target).to be(duped)
        expect(instance.target).not_to be(local)
      end
    end

    it "resets the thread local logger back to the original logger" do
      instance.silence :warn do; end
      expect(instance.target).to be(local)
    end

    context "level is not passed" do
      it "defaults to error" do
        expect(duped).to receive(:level=).with(:error)
        instance.silence do; end
      end
    end

    context "no thread local logger" do
      before do
        instance.set(nil)
        allow(default).to receive(:dup).and_return(duped)
      end

      it "sets a copy of the default logger configured at the given level" do
        expect(duped).to receive(:level=).with(:warn)

        instance.silence :warn do
          expect(instance.target).to be(duped)
          expect(instance.target).not_to be(default)
        end
      end

      it "resets the thread local logger back to nil" do
        instance.silence do; end
        expect(Thread.current[:pakyow_logger]).to be(nil)
      end
    end
  end
end
