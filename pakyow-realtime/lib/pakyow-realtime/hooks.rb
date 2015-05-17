Pakyow::App.after :init do
  Celluloid.logger = Pakyow.logger
end

Pakyow::App.before :route do
  if req.env['HTTP_UPGRADE'] == 'websocket'
		logger.info 'upgrading to websocket'

    socket_connection_id = params[:socket_connection_id]
    socket_digest = socket_digest(socket_connection_id)

    # create our websocket connection
    conn = Pakyow::Realtime::Websocket.new(req, socket_digest)

    # register the connection with a key
    Pakyow::Realtime::Delegate.instance.register(socket_digest, conn)

    # halt, so pakyow does nothing more
    halt
  end
end

Pakyow::App.after :process do
  if response.header['Content-Type'] == 'text/html'
    if body = response.body[0]
      body.gsub!(/<body/, '<body data-socket-connection-id="' + socket_connection_id + '"')
    end
  end
end
