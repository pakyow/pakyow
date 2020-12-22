require "pakyow/support/thread_localizer"

RSpec.describe Pakyow::Support::ThreadLocalizer do
  let(:object) {
    Class.new {
      include Pakyow::Support::ThreadLocalizer
    }
  }

  let(:instance) {
    object.new
  }

  before do
    allow(Thread.current).to receive(:[]=).and_call_original
  end

  describe "#thread_localize" do
    let(:key) {
      :foo
    }

    let(:value) {
      :bar
    }

    it "sets the thread local" do
      expect(described_class.thread_localized_store).to receive(:[]=).with(:"__pw_#{instance.object_id}_#{key}", value)

      instance.thread_localize(key, value)
    end

    it "defines a finalizer for the key" do
      expect(ObjectSpace).to receive(:define_finalizer) do |finalizable_instance, callable|
        expect(finalizable_instance).to be(instance)
        expect(callable.name).to eq(:cleanup_thread_localized_keys)
      end

      instance.thread_localize(key, value)
    end

    describe "the finalizer" do
      let(:finalizer) {
        @finalizer
      }

      before do
        instance.thread_localize(key, value)
      end

      it "removes the localized value" do
        expect(described_class.thread_localized_store).to receive(:delete).with(:"__pw_#{instance.object_id}_#{key}")

        instance.send(:cleanup_thread_localized_keys)
      end
    end
  end

  describe "#thread_localized" do
    before do
      instance.thread_localize(:foo, :bar)
    end

    it "returns the value from the current thread" do
      expect(instance.thread_localized(:foo)).to eq(:bar)
    end

    it "does not return the value from other instances" do
      expect(object.new.thread_localized(:foo)).to be(nil)
    end

    it "does not return the value from a child thread" do
      value = nil
      Thread.new { value = instance.thread_localized(:foo) }.join
      expect(value).to be(nil)
    end

    context "no value exists for the current thread" do
      it "returns nil" do
        expect(instance.thread_localized(:bar)).to be(nil)
      end
    end
  end

  describe "#delete_thread_localized" do
    before do
      instance.thread_localize(:foo, :bar)
    end

    it "deletes the localized value" do
      instance.delete_thread_localized(:foo)

      expect(instance.thread_localized(:foo)).to be(nil)
    end
  end
end
