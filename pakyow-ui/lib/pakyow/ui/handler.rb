# frozen_string_literal: true

require "pakyow/connection"

require "pakyow/realtime/channel"

# require "pakyow/ui/presenter"
require "pakyow/ui/recordable"

module Pakyow
  module UI
    class Handler
      def initialize(app)
        @app = app
      end

      def call(args, subscription: nil, result: nil)
        renderer = Marshal.restore(args[:metadata])[:renderer]
        renderer.presentables[:__ui_transform] = true
        renderer.perform

        @app.websocket_server.subscription_broadcast(
          Realtime::Channel.new(:transformation, subscription[:id]),
          { id: args[:transformation_id], calls: renderer.presenter }
        )
      end
    end
  end
end
