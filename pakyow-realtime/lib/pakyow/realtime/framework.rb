# frozen_string_literal: true

require "pakyow/core/framework"

require "pakyow/realtime/server"

module Pakyow
  module Realtime
    class Framework < Pakyow::Framework(:realtime)
      def boot
        app.class_eval do
          endpoint Server

          helper Helpers

          settings_for :realtime do
            # setting :registry, Pakyow::Realtime::SimpleRegistry
            # setting :redis, url: "redis://127.0.0.1:6379"
            # setting :redis_key, "pw:channels"
            # setting :delegate do
            #   Pakyow::Realtime::Delegate.new(config.realtime.registry.instance)
            # end

            # defaults :production do
            #   setting :registry, Pakyow::Realtime::RedisRegistry
            # end
          end

          unfreezable :websocket_server
          attr_reader :websocket_server

          after :configure do
            @websocket_server = Server.new
          end
        end

        if app.const_defined?(:Renderer)
          app.const_get(:Renderer).before :render do
            next unless head = @current_presenter.view.object.find_significant_nodes(:head)[0]

            # embed the socket connection id (used by pakyow.js to idenfity itself with the server)
            head.append("<meta name=\"pw-connection-id\" content=\"#{socket_connection_id}:#{socket_digest(socket_connection_id)}\">")

            # embed the socket connection path
            # TODO: this should be configurable
            head.append("<meta name=\"pw-connection-path\" content=\"/pw-socket\">")
          end
        end
      end
    end

    module Helpers
      def socket_key
        return request.params[:socket_key] if request.params[:socket_key]
        request.session[:socket_key] ||= Server.socket_key
      end

      def socket_connection_id
        return request.params[:socket_connection_id] if request.params[:socket_connection_id]
        @socket_connection_id ||= Server.socket_connection_id
      end

      def socket_digest(socket_connection_id)
        Server.socket_digest(socket_key, socket_connection_id)
      end
    end
  end
end
