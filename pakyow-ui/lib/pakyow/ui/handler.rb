# frozen_string_literal: true

require "pakyow/connection"
require "pakyow/logger/request_logger"

require "pakyow/presenter/rendering/view_renderer"

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
          presentable_hash[presentable_name] = @app.data.public_send(
            proxy[:source]
          ).apply(proxy[:proxied_calls])
        }

        env = args[:env]
        env["rack.input"] = StringIO.new
        env[Rack::RACK_LOGGER] = Logger::RequestLogger.new(:"  ui")

        connection = Connection.new(@app, env)
        connection.instance_variable_set(:@values, presentables)

        base_renderer_class = if @app.class.const_defined?(args[:renderer][:class_name])
          @app.class.const_get(args[:renderer][:class_name])
        else
          @app.subclass(:ViewRenderer)
        end

        renderer_class = @app.ui_renderers.find { |ui_renderer|
          ui_renderer.ancestors.include?(base_renderer_class)
        }

        renderer = renderer_class.restore(connection, args[:renderer][:serialized])
        renderer.perform

        message = { id: args[:transformation_id], calls: renderer.presenter }
        @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, subscription[:id]), message)
      end
    end
  end
end
