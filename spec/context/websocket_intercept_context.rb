class WebSocketIntercept
  attr_reader :broadcasts

  def initialize
    @adapter = self
    @broadcasts = []
  end

  def subscription_broadcast(*, message:, **)
    @broadcasts << message
  end

  def socket_subscribe(*)
  end

  def socket_unsubscribe(*)
  end

  def find_socket_id(*)
  end
end

RSpec.shared_context "websocket intercept" do
  def ws_intercept
    yield

    interceptor = WebSocketIntercept.new

    until Pakyow::Realtime::Server.queue.empty?
      block = Pakyow::Realtime::Server.queue.pop
      interceptor.instance_eval(&block)
    end

    interceptor.broadcasts
  end
end
