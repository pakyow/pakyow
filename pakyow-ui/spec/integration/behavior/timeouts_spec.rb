RSpec.describe "ui state timeout behavior" do
  include_context "app"

  let :socket_id do
    Pakyow::Support::MessageVerifier.key
  end

  let :connection do
    Pakyow.app(:test).isolated(:Connection).new(
      Pakyow.app(:test),
      Pakyow::Connection.new(
        request
      )
    )
  end

  let :request do
    Async::HTTP::Protocol::Request.new(
      "http", "localhost", "GET", "/", nil, HTTP::Protocol::Headers.new([["content-type", "text/html"]])
    ).tap do |request|
      request.remote_address = Addrinfo.tcp("0.0.0.0", "http")
    end
  end

  let :socket do
    allow(Async::WebSocket::Incoming).to receive(:new)
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
      Pakyow.app(:test).isolated(:Renderer).new(
        app: Pakyow.app(:test),
        presentables: connection.values,
        presenter_class: Pakyow.app(:test).isolated(:Presenter),
        composer: composer.new
      )
    end

    let :composer do
      Class.new do
        def key
          ""
        end

        def view(app:)
          Pakyow::Presenter::View.new("")
        end
      end
    end

    it "expires the socket id data subscription, using the initial timeout" do
      expect(
        Pakyow.app(:test).data
      ).to receive(:expire).with(socket_id, Pakyow.app(:test).config.realtime.timeouts.initial)

      view_renderer.perform
    end
  end
end
