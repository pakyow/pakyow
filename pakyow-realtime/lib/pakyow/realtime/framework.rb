# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/support/message_verifier"

require "pakyow/realtime/channel"
require "pakyow/realtime/server"

require "pakyow/realtime/behavior/silencing"

module Pakyow
  module Realtime
    class WebSocketUpgrader
      def initialize(_)
      end

      def call(connection)
        return unless Pakyow.config.realtime.server
        return unless connection.path == "/pw-socket"
        return unless ::WebSocket::Driver.websocket?(connection.env)

        # Verify that the websocket is connecting with a valid digest.
        #
        # We expect to receive an id and digest, separated by a colon. The digest is
        # generated from the id along with the key. When the client is a browser, the
        # `id:digest` value is embedded in the response, while the key is stored in
        # the session. We verify by generating the digest and comparing it to the
        # digest sent in the connection attempt.
        id, digest = connection.params[:id].to_s.split(":", 2)
        return unless Support::MessageVerifier.valid?(
          id, digest: digest, key: connection.session[:socket_server_id]
        )

        WebSocket.new(id, connection)
        connection.halt
      end
    end

    class Framework < Pakyow::Framework(:realtime)
      def boot
        Pakyow.module_eval do
          settings_for :realtime do
            setting :server, true

            setting :adapter, :memory
            setting :adapter_options, {}

            defaults :production do
              setting :adapter, :redis
              setting :adapter_options, redis_url: ENV["REDIS_URL"] || "redis://127.0.0.1:6379", redis_prefix: "pw"
            end
          end
        end

        app.class_eval do
          action WebSocketUpgrader

          include Behavior::Silencing

          helper Helpers

          settings_for :realtime do
            setting :adapter_options, {}
            setting :path, "pw-socket"
            setting :endpoint
            setting :log_initial_request, false

            defaults :production do
              setting :adapter_options do
                { redis_prefix: ["pw", config.name].join("/") }
              end

              setting :log_initial_request, true
            end
          end

          unfreezable :websocket_server
          attr_reader :websocket_server

          after :configure do
            @websocket_server = Server.new(
              Pakyow.config.realtime.adapter,
              Pakyow.config.realtime.adapter_options.merge(config.realtime.adapter_options)
            )
          end

          known_events :join, :leave
        end

        if app.const_defined?(:Renderer)
          app.const_get(:Renderer).tap do |renderer_class|
            renderer_class.include Helpers
            renderer_class.before :render do
              next unless head = @presenter.view.object.find_significant_nodes(:head)[0]

              # embed the socket connection id (used by pakyow.js to idenfity itself with the server)
              head.append("<meta name=\"pw-connection-id\" content=\"#{socket_client_id}:#{socket_digest(socket_client_id)}\">\n")

              # embed the endpoint we'll be connecting to
              endpoint = @connection.app.config.realtime.endpoint

              unless endpoint
                endpoint = if Pakyow.env?(:development) || Pakyow.env?(:prototype)
                  # Connect directly to the app in development, since the proxy
                  # does not support websocket connections.
                  #
                  File.join("ws://#{Pakyow.host}:#{Pakyow.port}", @connection.app.config.realtime.path)
                else
                  File.join("#{@connection.ssl? ? "wss" : "ws"}://#{@connection.request.host_with_port}", @connection.app.config.realtime.path)
                end
              end

              head.append("<meta name=\"pw-endpoint\" content=\"#{endpoint}\">\n")
            end
          end
        end
      end
    end

    module Helpers
      require "pakyow/support/message_verifier"

      def broadcast(message)
        @connection.app.websocket_server.subscription_broadcast(socket_client_id, message)
      end

      def subscribe(channel, qualifier = nil)
        @connection.app.websocket_server.socket_subscribe(socket_client_id, Channel.new(channel, qualifier))
      end

      def unsubscribe(channel, qualifier = "*")
        @connection.app.websocket_server.socket_unsubscribe(Channel.new(channel, qualifier))
      end

      def socket_server_id
        return @connection.params[:socket_server_id] if @connection.params[:socket_server_id]
        @connection.session[:socket_server_id] ||= Support::MessageVerifier.key
      end

      def socket_client_id
        return @connection.params[:socket_client_id] if @connection.params[:socket_client_id]
        @socket_client_id ||= Support::MessageVerifier.key
      end

      def socket_digest(socket_client_id)
        Support::MessageVerifier.digest(socket_client_id, key: socket_server_id)
      end
    end
  end
end
