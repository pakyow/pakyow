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

      def call(args, subscription: nil, result: nil)
        presentables = args[:presentables].each_with_object({}) { |presentable_info, presentable_hash|
          if presentable_info.key?(:ephemeral)
            ephemeral = Data::Sources::Ephemeral.restore(presentable_info[:ephemeral])
            presentable_hash[presentable_info[:name]] = if result && result.type == ephemeral.type && result.qualifications == ephemeral.qualifications
              result
            else
              ephemeral
            end
          elsif presentable_info.key?(:proxy)
            presentable_hash[presentable_info[:name]] = @app.data.public_send(
              presentable_info[:proxy][:source]
            ).apply(presentable_info[:proxy][:proxied_calls])
          else
            presentable_hash[presentable_info[:name]] = presentable_info[:value]
          end
        }

        env = args[:env]
        env["pakyow.ui_transform"] = true
        env["rack.input"] = StringIO.new
        env[Rack::RACK_LOGGER] = Logger::RequestLogger.new(:"  ui")

        connection = Connection.new(@app, env)
        connection.instance_variable_set(:@values, presentables)

        base_renderer_class = if @app.class.const_defined?(args[:renderer][:class_name])
          @app.class.const_get(args[:renderer][:class_name])
        else
          @app.isolated(:ViewRenderer)
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
