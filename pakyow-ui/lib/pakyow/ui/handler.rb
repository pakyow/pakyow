# frozen_string_literal: true

require "pakyow/connection"

require "pakyow/data/proxy"
require "pakyow/data/sources/ephemeral"

require "pakyow/realtime/channel"

require_relative "recordable"

module Pakyow
  module UI
    # @api private
    class Handler
      def initialize(app)
        @app = app
      end

      def call(args, subscription: nil, result: nil)
        renderer = Marshal.restore(args[:metadata])[:renderer]
        renderer.presentables[:__ui_transform] = true

        # If an ephemeral caused the update, replace the value for any matching presentables.
        #
        if result.is_a?(Data::Sources::Ephemeral)
          renderer.presentables.each do |key, value|
            if value.is_a?(Data::Proxy) && value.source.is_a?(Data::Sources::Ephemeral) && value.source.type == result.type && value.source.qualifications == result.qualifications
              value.instance_variable_set(:@source, result)
            end
          end
        end

        renderer.perform

        @app.websocket_server.subscription_broadcast(
          Realtime::Channel.new(:transformation, subscription[:id]),
          {id: args[:transformation_id], calls: renderer.presenter}
        )
      end
    end
  end
end
