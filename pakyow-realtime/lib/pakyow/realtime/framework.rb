# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/realtime/channel"
require "pakyow/realtime/server"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        Pakyow.module_eval do
          settings_for :realtime do
            setting :adapter, :memory
            setting :adapter_options, {}

            defaults :production do
              setting :adapter, :redis
              setting :adapter_options, redis_url: "redis://127.0.0.1:6379", redis_prefix: "pw"
            end
          end
        end

        app.class_eval do
          endpoint Server

          helper Helpers

          settings_for :realtime do
            setting :adapter_options, {}

            defaults :production do
              setting :adapter_options, Proc.new do
                { redis_prefix: ["pw", config.app.name].join("/") }
              end
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
          app.const_get(:Renderer).before :render do
            next unless head = @current_presenter.view.object.find_significant_nodes(:head)[0]

            # embed the socket connection id (used by pakyow.js to idenfity itself with the server)
            head.append("<meta name=\"pw-connection-id\" content=\"#{socket_client_id}:#{socket_digest(socket_client_id)}\">")

            # embed the socket connection path
            # TODO: this should be configurable
            head.append("<meta name=\"pw-connection-path\" content=\"/pw-socket\">")
          end
        end
      end
    end

    module Helpers
      def broadcast(message)
        app.websocket_server.subscription_broadcast(socket_client_id, message)
      end

      def subscribe(channel, qualifier = nil)
        app.websocket_server.socket_subscribe(socket_client_id, Channel.new(channel, qualifier))
      end

      def unsubscribe(channel, qualifier = nil)
        app.websocket_server.socket_unsubscribe(socket_client_id, Channel.new(channel, qualifier))
      end

      def socket_server_id
        return request.params[:socket_server_id] if request.params[:socket_server_id]
        request.session[:socket_server_id] ||= Server.socket_client_id
      end

      def socket_client_id
        return request.params[:socket_client_id] if request.params[:socket_client_id]
        @socket_client_id ||= Server.socket_client_id
      end

      def socket_digest(socket_client_id)
        Server.socket_digest(socket_server_id, socket_client_id)
      end
    end
  end
end
