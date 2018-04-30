# frozen_string_literal: true

require "json"
require "digest"

require "pakyow/core/framework"

require "pakyow/ui/presenter"
require "pakyow/ui/renderer"
require "pakyow/ui/transformation"

module Pakyow
  module UI
    class Framework < Pakyow::Framework(:ui)
      # How long we want to wait before cleaning up data subscriptions. We set the subscriber
      # (the WebSocket connection) to expire when it's initially created. This way if it never
      # connects the subscription will be cleaned up, preventing orphaned subscriptions. We
      # schedule an expiration on disconnect for the same reason.
      #
      # When the WebSocket connects, we persist the subscriber, cancelling the expiration.
      #
      SUBSCRIPTION_TIMEOUT = 60

      def boot
        app.on :join do
          @connection.app.data.persist(@id)
        end

        app.on :leave do
          @connection.app.data.expire(@id, SUBSCRIPTION_TIMEOUT)
        end

        if app.const_defined?(:Renderer)
          handler = Class.new do
            def initialize(app)
              @app = app
            end

            def call(args, subscription: nil, subscription_ids: [])
              presentables = args[:presentables].each_with_object({}) { |presentable_info, presentable_hash|
                presentable_name, proxy = presentable_info.values_at(:name, :proxy)

                # convert data to an array, because the client can always deal arrays
                presentable_hash[presentable_name] = @app.data.public_send(
                  proxy[:source]
                ).apply(proxy[:proxied_calls]).to_a
              }

              renderer = Renderer.new(@app, presentables)
              renderer.perform(args[:view_path])

              message = { transformation_id: args[:transformation_id], transformations: renderer.to_arr }
              @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, subscription[:id]), message)

              # resubscribe websockets to the new subscriptions
              subscription_ids.each do |subscription_id|
                @app.websocket_server.socket_unsubscribe(Realtime::Channel.new(:transformation, subscription[:id]))
                @app.websocket_server.socket_subscribe(args[:socket_client_id], Realtime::Channel.new(:transformation, subscription_id))
              end
            end
          end

          app.const_set(:MutationHandler, handler)

          app.const_get(:Renderer).before :render do
            # The transformation id doesn't have to be completely unique, just unique to the presenter.
            @transformation_id = Digest::SHA1.hexdigest(@presenter.class.object_id.to_s)

            # To keep up with the node(s) that matter for the transformation, a `data-t` attribute
            # is added to the node that contains the transformation_id. When the transformation is
            # triggered in the future, the client knows what node to apply tranformations to.
            #
            # Note that when we're presenting an entire view, `data-t` is set on the `body` node.

            if node = @presenter.view.object.find_significant_nodes(:body)[0]
              node.attributes[:"data-t"] = @transformation_id
            else
              # TODO: mixin the transformation_id into other nodes, once supported in presenter
              #
              # These views are going to be much harder. For example, partials. The partial
              # doesn't really exist after rendering, so we need a way to identify it in the
              # view. Probably what makes sense is to add `data-t` to every top-level node
              # in these cases. Then deal with the nodes in a cumulative way on the client.
            end
          end

          app.const_get(:Renderer).after :render do
            # We wait until after render so that we don't create subscriptions unnecessarily
            # in the event that something blew up during the render process.
            #
            presentables = @connection.values.select { |_, presentable|
              presentable.is_a?(Data::Proxy)
            }

            metadata = {
              view_path: @presenter.class.path,
              transformation_id: @transformation_id,
              socket_client_id: socket_client_id,
              presentables: presentables.map { |presentable_name, presentable|
                { name: presentable_name, proxy: presentable.to_h }
              }
            }

            # Find every subscribable presentable, creating a data subscription for each.
            #
            presentables.values.select(&:subscribable?).each do |subscribable|
              subscribable.subscribe(socket_client_id, handler: handler, payload: metadata).each do |subscription_id|
                @connection.app.data.expire(socket_client_id, SUBSCRIPTION_TIMEOUT)

                # Create the socket subscription on the "transformation" channel.
                #
                subscribe(:transformation, subscription_id)
              end
            end
          end
        end
      end
    end
  end
end
