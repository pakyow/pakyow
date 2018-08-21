# frozen_string_literal: true

require "pakyow/connection"
require "pakyow/logger/request_logger"

require "pakyow/presenter/renderer"

require "pakyow/realtime/channel"

module Pakyow
  module UI
    class Handler
      def initialize(app)
        @app = app
      end

      def call(args, subscription: nil)
        presentables = args[:presentables].each_with_object({}) { |presentable_info, presentable_hash|
          presentable_name, proxy = presentable_info.values_at(:name, :proxy)

          # convert data to an array, because the client can always deal arrays
          presentable_hash[presentable_name] = @app.data.public_send(
            proxy[:source]
          ).apply(proxy[:proxied_calls])
        }

        env = args[:env]
        env["rack.input"] = StringIO.new
        env[Rack::RACK_LOGGER] = Logger::RequestLogger.new(:"  ui")

        connection = Connection.new(@app, env)
        connection.instance_variable_set(:@values, presentables)

        renderer = Renderer.new(
          connection,
          as: args[:as],
          path: args[:path],
          layout: args[:layout],
          mode: args[:mode]
        )

        renderer.presenter.call

        message = { id: args[:transformation_id], calls: renderer.presenter }
        @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, subscription[:id]), message)
      end
    end
  end
end
