RSpec.describe Pakyow::Realtime::WebSocket do
  let :instance do
    described_class.new(id, connection)
  end

  let :id do
    "42"
  end

  let :connection do
    double(
      :connection,
      app: application,
      request: nil,
      __getobj__: underlying_connection
    )
  end

  let :underlying_connection do
    double(
      :underlying_connection
    )
  end

  let :logger do
    double(
      :logger,
      info: nil
    )
  end

  let :application do
    double(
      :application,
      websocket_server: websocket_server,
      hooks: [],
      config: config
    )
  end

  let :websocket_server do
    double(
      :websocket_server,
      socket_connect: nil,
      socket_disconnect: nil
    )
  end

  let :socket do
    double(
      :socket,
      close: nil,
      write: nil,
      flush: nil,
      read: nil
    )
  end

  let :config do
    double(
      :config,
      version: "123"
    )
  end

  before do
    allow(Pakyow::Logger).to receive(:new).and_return(logger)
    allow(Async::WebSocket::Adapters::Native).to receive(:open) do |&block|
      Async do
        block.call(socket)
      end
    end
  end

  describe "heartbeat" do
    it "has a heartbeat after connecting" do
      allow(socket).to receive(:read) do
        Async::Task.current.sleep 3
      end

      Async {
        expect(instance).to receive(:beat).at_least(:twice)
      }.wait
    end

    it "does not have a heartbeat after disconnecting" do
      expect(instance).not_to receive(:beat)
      sleep 3
    end
  end
end
