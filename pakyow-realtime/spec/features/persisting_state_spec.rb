RSpec.describe "persisting state on shutdown" do
  include_context "testable app"

  let :autorun do
    false
  end

  let :cached_state_path do
    File.join(Pakyow.config.root, "tmp/state")
  end

  context "using the memory adapter" do
    before do
      Pakyow.after :configure do
        config.realtime.adapter = :memory
      end
    end

    after do
      if File.exist?(cached_state_path)
        FileUtils.rm_r(cached_state_path)
      end
    end

    it "serializes the server on shutdown" do
      run_app

      expect(Pakyow::Support::Serializer).to receive(:new).with(
        Pakyow.apps.first.websocket_server.adapter,
        name: "test-realtime", path: cached_state_path
      ).and_call_original

      Pakyow.apps.first.shutdown

      expect(
        File.exist?(File.join(cached_state_path, "test-realtime.pwstate"))
      ).to be(true)
    end

    it "deserializes the server on boot" do
      require "pakyow/realtime/server/adapters/memory"
      serializer = instance_double(Pakyow::Support::Serializer)
      expect(Pakyow::Support::Serializer).to receive(:new).with(
        instance_of(Pakyow::Realtime::Server::Adapters::Memory),
        name: "test-realtime", path: cached_state_path
      ).and_return(serializer)

      expect(serializer).to receive(:deserialize)

      run_app
    end
  end

  context "using a non-memory adapter" do
    before do
      Pakyow.after :configure do
        config.realtime.adapter = :redis
      end
    end

    it "does not attempt to serialize the server on shutdown" do
      run_app

      Pakyow.apps.first.shutdown

      expect(
        File.exist?(File.join(cached_state_path, "test-realtime.pwstate"))
      ).to be(false)
    end

    it "does not attempt to deserialize the server on boot" do
      expect_any_instance_of(Pakyow::Support::Serializer).not_to receive(:deserialize)

      run_app
    end
  end
end
