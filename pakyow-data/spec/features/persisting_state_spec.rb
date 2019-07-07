RSpec.describe "persisting state on shutdown" do
  include_context "app"

  let :autorun do
    false
  end

  let :cached_state_path do
    File.join(Pakyow.config.root, "tmp/state")
  end

  context "using the memory adapter" do
    before do
      Pakyow.after "configure" do
        config.data.subscriptions.adapter = :memory
      end
    end

    after do
      if File.exist?(cached_state_path)
        FileUtils.rm_r(cached_state_path)
      end
    end

    it "serializes the subscribers on shutdown" do
      setup_and_run

      expect(Pakyow::Support::Serializer).to receive(:new).with(
        Pakyow.apps.first.data.subscribers.adapter,
        name: "test-subscribers", path: cached_state_path, logger: Pakyow.logger
      ).and_call_original

      Pakyow.apps.first.shutdown

      expect(
        File.exist?(File.join(cached_state_path, "test-subscribers.pwstate"))
      ).to be(true)
    end

    it "deserializes the subscribers on boot" do
      require "pakyow/data/subscribers/adapters/memory"
      serializer = instance_double(Pakyow::Support::Serializer)
      expect(Pakyow::Support::Serializer).to receive(:new).with(
        instance_of(Pakyow::Data::Subscribers::Adapters::Memory),
        name: "test-subscribers", path: cached_state_path, logger: instance_of(Pakyow::Logger::ThreadLocal)
      ).and_return(serializer)

      expect(serializer).to receive(:deserialize)

      setup_and_run
    end
  end

  context "using a non-memory adapter" do
    before do
      Pakyow.after "configure" do
        config.data.subscriptions.adapter = :redis
        config.data.subscriptions.adapter_settings = Pakyow.config.redis.dup
      end
    end

    it "does not attempt to serialize the subscribers on shutdown" do
      setup_and_run

      Pakyow.apps.first.shutdown

      expect(
        File.exist?(File.join(cached_state_path, "test-subscribers.pwstate"))
      ).to be(false)
    end

    it "does not attempt to deserialize the subscribers on boot" do
      expect_any_instance_of(Pakyow::Support::Serializer).not_to receive(:deserialize)

      setup_and_run
    end
  end

  context "app failed to boot, so data lookup is nil" do
    before do
      setup_and_run
      Pakyow.apps[0].remove_instance_variable(:@data)
    end

    it "does not try to shut down" do
      expect {
        Pakyow.apps[0].shutdown
      }.not_to raise_error
    end
  end
end
