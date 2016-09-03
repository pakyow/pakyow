module Pakyow
  module Realtime
    module Middleware
      Pakyow::App.middleware do |builder|
        if Pakyow::Config.realtime.enabled
          builder.use Pakyow::Realtime::Middleware::WebSocketUpgrader
        end
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
      class WebSocketUpgrader
        UPGRADE_CMP = "websocket"

        def initialize(app)
          @app = app
        end

        def call(env)
          if websocket?(env)
            handshake = Handshake.new(env)
            handshake.perform

            if handshake.valid?
              handshake.finalize(hijack(env))
              req = Rack::Request.new(env)
              
              ConnectionPool.instance << Connection.new(
                handshake.io,
                version: handshake.server.version,
                env: handshake.env,
                key: Connection.socket_digest(req.session[:socket_key], req.params["socket_connection_id"])
              )

              [200, {}, ""]
            else
              [400, {}, ""]
            end
          else
            @app.call(env)
          end
        end

        private

        def websocket?(env)
          env["HTTP_UPGRADE"] && env["HTTP_UPGRADE"].casecmp(UPGRADE_CMP) == 0
        end

        def hijack(env)
          return unless env["rack.hijack"]
          env["rack.hijack"].call
          env["rack.hijack_io"]
        end
      end
    end
  end
end
