RSpec.describe "ui state timeout behavior" do
  include_context "testable app"

  let :socket_id do
    Pakyow::Support::MessageVerifier.key
  end

  let :connection do
    env = Rack::MockRequest.env_for("/")
    env["HTTP_HOST"] = "localhost"
    env["REQUEST_URI"] = "/"
    io = Tempfile.new("hijack")
    env["rack.hijack"] = Proc.new { io }
    env["rack.hijack_io"] = io
    Pakyow::Connection.new(Pakyow.app(:test), env)
  end

  let :socket do
    Pakyow::Realtime::WebSocket.new(socket_id, connection)
  end

  before do
    socket

    connection.set(:__socket_client_id, socket_id)
  end

  context "socket joins" do
    it "persists the socket id data subscription" do
      expect(
        Pakyow.app(:test).data
      ).to receive(:persist).with(socket_id)

      socket.send(:trigger_presence, :join)
    end
  end

  context "socket leaves" do
    it "expires the socket id data subscription, using the disconnect timeout" do
      expect(
        Pakyow.app(:test).data
      ).to receive(:expire).with(socket_id, Pakyow.app(:test).config.realtime.timeouts.disconnect)

      socket.send(:trigger_presence, :leave)
    end
  end

  context "view renders" do
    let :view_renderer do
      Pakyow.app(:test).isolated(:ViewRenderer).new(
        connection,
        templates_path: "/",
        presenter_path: "/"
      )
    end

    let :view do
      Pakyow::Presenter::View.new("")
    end

    it "expires the socket id data subscription, using the initial timeout" do
      allow(Pakyow.app(:test)).to receive(:build_view).and_return(view)

      expect(
        Pakyow.app(:test).data
      ).to receive(:expire).with(socket_id, Pakyow.app(:test).config.realtime.timeouts.initial)

      view_renderer.perform
    end
  end
end
