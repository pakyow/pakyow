# frozen_string_literal: true

module Pakyow
  UPGRADE_CMP = "websocket".freeze

  def self.websocket?(env)
    env["HTTP_UPGRADE"] && env["HTTP_UPGRADE"].casecmp(UPGRADE_CMP) == 0
  end

  def self.hijack(env)
    return unless env["rack.hijack"]
    env["rack.hijack"].call
    env["rack.hijack_io"]
  end

  # Upgrades a WebSocket request and establishes the connection.
  #
  # When a connection is established it's added to the `ConnectionPool`
  # singleton, which is responsible for reading from the socket.
  #
  # Each connection is created with a digest, created from the connection
  # id (passed through the request) and the key (stored in the session).
  # Because the connection id is unique to each request, each digest is
  # valid for the lifetime of a connection. Browsing to a new page, for
  # instance, would create a new connection with a unique digest.
  #
  # This allows channel subscriptions created for a connection to be trusted
  # when the connection is ultimately established, because if either the id
  # or key is incorrect, the digest will not match and the connection will
  # not be properly identified and won't receive messages.
  #
  # Doing this essentially guarantee that the connection is established for
  # the same session the channel subscriptions were initially created for.
  #
  Controller.before :process do
    if Pakyow.websocket?(request.env)
      handshake = Realtime::Handshake.new(request.env)
      handshake.perform

      if handshake.valid?
        handshake.finalize(Pakyow.hijack(request.env))
        req = Rack::Request.new(request.env)

        Realtime::ConnectionPool.instance << Realtime::Connection.new(
          handshake.io,
          version: handshake.server.version,
          env: handshake.env,
          key: Realtime::Connection.socket_digest(req.session[:socket_key], req.params["socket_connection_id"]),
          delegate: app.config.realtime.delegate
        )

        halt
      else
        response.status = 400
        halt
      end
    end
  end

  Controller.before :render do
    next unless app.config.realtime.enabled
    next unless body = @current_presenter.view.object.find_significant_nodes(:body)[0]

    # mixin the socket connection id into the body tag
    # this id is used by pakyow.js to idenfity itself with the server
    body.attributes[:"data-socket-connection-id"] = socket_connection_id
  end

  after :fork do
    Realtime::ConnectionPool.instance.wakeup
  end
end
