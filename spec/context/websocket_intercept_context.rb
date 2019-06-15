class WebSocketIntercept
  attr_reader :broadcasts

  def initialize
    @broadcasts = []
  end

  def subscription_broadcast(channel, message)
    @broadcasts << message
  end

  def socket_subscribe(*)
  end

  def socket_unsubscribe(*)
  end
end

RSpec.shared_context "websocket intercept" do
  def ws_intercept
    app = Pakyow.apps.first
    interceptor = WebSocketIntercept.new

    # allow(app).to receive(:websocket_server).at_least(:once).and_return(interceptor)
    app.instance_variable_set(:@websocket_server, interceptor)

    app.plugs.each do |plug|
      # allow(plug).to receive(:websocket_server).at_least(:once).and_return(interceptor)
      plug.instance_variable_set(:@websocket_server, interceptor)
    end

    yield

    interceptor.broadcasts
  end
end
