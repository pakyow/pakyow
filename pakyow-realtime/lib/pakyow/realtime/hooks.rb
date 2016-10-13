module Pakyow
  before :setup do
    use Realtime::Middleware::WebSocketUpgrader
  end

  CallContext.after :process do
    # mixin the socket connection id into the body tag
    # this id is used by pakyow.js to idenfity itself with the server
    #
    if response.header['Content-Type'].include?('text/html') && Config.realtime.enabled
      next if !response.body.is_a?(Array)

      body = response.body.first
      next if body.nil?

      mixin = '<body data-socket-connection-id="' + socket_connection_id + '"'
      body.gsub!(/<body/, mixin)
    end
  end

  App.after :fork do
    Realtime::ConnectionPool.instance.wakeup
  end
end
