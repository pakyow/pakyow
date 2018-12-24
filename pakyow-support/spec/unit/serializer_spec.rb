require "pakyow/support/serializer"

RSpec.describe Pakyow::Support::Serializer do
  let :serializable do
    Class.new do
      def initialize(value)
        @value = value
      end

      def serialize
        { :@value => @value }
      end
    end
  end

  let :deserializable do
    Class.new do
      attr_reader :value
    end
  end

  let :serializer do
    described_class.new(
      serializable.new("foo"), name: "test", path: cache_path
    )
  end

  let :deserializer do
    described_class.new(
      deserializable.new, name: "test", path: cache_path
    )
  end

  let :cache_path do
    File.expand_path("../serializer-cache", __FILE__)
  end

  let :cached_state_path do
    File.join(cache_path, "test.pwstate")
  end

  let :cached_state do
    Marshal.load(File.read(cached_state_path))
  end

  let :logger do
    double(:logger)
  end

  after do
    if File.exist?(cache_path)
      FileUtils.rm_r(cache_path)
    end
  end

  describe "#serialize" do
    it "ensures that the cache path exists" do
      expect {
        serializer.serialize
      }.to change {
        File.exist?(cache_path)
      }.from(false).to(true)
    end

    it "writes the serialized object" do
      serializer.serialize
      expect(File.exist?(cached_state_path)).to be(true)
    end

    context "serialization fails" do
      before do
        expect(Marshal).to receive(:dump).and_raise(error)
      end

      let :error do
        RuntimeError.new
      end

      it "safely logs the error" do
        expect(Pakyow::Support::Logging).to receive(:yield_or_raise) do |error, &block|
          expect(error).to be(error)

          expect(logger).to receive(:error).with("[Serializer] failed to serialize `test': RuntimeError")
          block.call(logger)
        end

        serializer.serialize
      end
    end
  end

  describe "#deserialize" do
    context "cached state exists" do
      before do
        serializer.serialize
      end

      it "loads the serialized state on the object" do
        deserializer.deserialize
        expect(deserializer.object.value).to eq("foo")
      end

      context "deserialization fails" do
        before do
          expect(Marshal).to receive(:load).and_raise(error)
        end

        let :error do
          RuntimeError.new
        end

        it "safely logs the error" do
          expect(Pakyow::Support::Logging).to receive(:yield_or_raise) do |error, &block|
            expect(error).to be(error)

            expect(logger).to receive(:error).with("[Serializer] failed to deserialize `test': RuntimeError")
            block.call(logger)
          end

          serializer.deserialize
        end

        it "removes the cached state" do
          expect(FileUtils).to receive(:rm).with(cached_state_path)

          begin
            serializer.deserialize
          rescue
          end
        end
      end
    end

    context "cached state does not exist" do
      it "does not fail" do
        expect {
          deserializer.deserialize
        }.not_to raise_error
      end
    end
  end
end
