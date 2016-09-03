Pakyow::CallContext.after :process do
  # mixin the socket connection id into the body tag
  # this id is used by pakyow.js to idenfity itself with the server
  #
  if response.header['Content-Type'].include?('text/html') && Pakyow::Config.realtime.enabled
    next if !response.body.is_a?(Array)

    body = response.body.first
    next if body.nil?

    mixin = '<body data-socket-connection-id="' + socket_connection_id + '"'
    body.gsub!(/<body/, mixin)
  end
end

Pakyow::App.after :fork do
  Pakyow::Realtime::ConnectionPool.instance.wakeup
end
