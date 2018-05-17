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
    interceptor = WebSocketIntercept.new
    expect(Pakyow.apps.first).to receive(:websocket_server).at_least(:once).and_return(interceptor)
    yield
    interceptor.broadcasts
  end
end
