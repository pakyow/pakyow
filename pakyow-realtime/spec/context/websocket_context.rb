RSpec.shared_context "websocket" do
  class MockConnection
    attr_reader :app

    def initialize(app)
      @app = app
    end
  end

  class MockWebSocket < Pakyow::Realtime::WebSocket
    def initialize(app)
      id = SecureRandom.hex(4)
      connection = MockConnection.new(app)
      super(id, connection)
    end

    def open
    end

    def <<(payload)
      handle_message(payload.to_json)
    end
  end

  let :websocket do
    MockWebSocket.new(Pakyow.app(websocket_app_name))
  end

  let :websocket_app_name do
    :test
  end
end
