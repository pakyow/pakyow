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

  let :application do
    double(
      :application,
      websocket_server: websocket_server,
      each_hook: nil,
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
    allow(Pakyow.logger).to receive(:info)

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

  describe "logger" do
    context "within the open task" do
      it "replaces the thread local" do
        type = nil
        allow(socket).to receive(:read) do
          type = Pakyow.logger.target.type
          Async::Task.current.sleep 1
        end

        Async {
          instance
        }.wait

        expect(type).to eq(:sock)
      end

      it "sets the websocket logger to the thread local" do
        expect(Pakyow.logger).to receive(:info)

        Async {
          instance
        }.wait
      end
    end

    it "does not alter the thread local of the parent task" do
      instance.shutdown

      expect(Pakyow.logger.target.type).to eq("dflt")
    end

    it "replaces the websocket logger with the original" do
      instance.shutdown

      expect(instance.logger.type).to eq(:sock)
    end
  end
end
