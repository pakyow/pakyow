Pakyow::App.before :route do
  # we want to hijack websocket requests
  #
  if req.env['HTTP_UPGRADE'] == 'websocket'
    if Pakyow::Config.realtime.enabled
      socket_connection_id = params[:socket_connection_id]
      socket_digest = socket_digest(socket_connection_id)

      begin
        conn = Pakyow::Realtime::Websocket.new(req, socket_digest)
      rescue Pakyow::Realtime::HandshakeError => e
        logger.error e.message
        res.status = 400
        halt
      end

      # register the connection with a unique key
      Pakyow::Realtime::Delegate.instance.register(socket_digest, conn)

      # tell the connection that it's registered
      conn.registered
    end

    halt
  end
end

Pakyow::App.after :process do
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
