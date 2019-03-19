# frozen_string_literal: true

require "pakyow/connection"

require "pakyow/presenter/rendering/view_renderer"

require "pakyow/realtime/channel"

module Pakyow
  module UI
    class Handler
      def initialize(app)
        @app = app
      end

      def call(args, subscription: nil, result: nil)
        metadata = Marshal.restore(args[:metadata])
        presentables = metadata[:presentables].each_with_object({}) { |presentable_info, presentable_hash|
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

        # env = metadata[:env]

        # TODO: set this as an app connection value
        # env["pakyow.ui_transform"] = true
        # env["rack.input"] = StringIO.new
        # env[Rack::RACK_LOGGER] = RequestLogger.new(:pwui)

        # connection = Connection.new(@app, env)
        connection = @app.class.isolated(:Connection).deserialize(metadata[:connection])
        # TODO: if we can serialize presentables properly, we won't have to worry about doing this
        connection.instance_variable_set(:@values, presentables)
        connection.set(:__ui_transform, true)

        base_renderer_class = if @app.class.const_defined?(metadata[:renderer][:class_name])
          @app.class.const_get(metadata[:renderer][:class_name])
        else
          @app.isolated(:ViewRenderer)
        end

        renderer_class = @app.ui_renderers.find { |ui_renderer|
          ui_renderer.ancestors.include?(base_renderer_class)
        }

        options = if renderer_class.ancestors.include?(@app.isolated(:ComponentRenderer))
          { descend: false }
        else
          {}
        end

        renderer = renderer_class.restore(connection, metadata[:renderer][:serialized], **options)
        renderer.perform

        message = { id: args[:transformation_id], calls: renderer.presenter }
        @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, subscription[:id]), message)
      end
    end
  end
end
