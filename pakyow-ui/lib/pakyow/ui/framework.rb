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
          app.data.persist(@id)
        end

        app.on :leave do
          app.data.expire(@id, SUBSCRIPTION_TIMEOUT)
        end

        if app.const_defined?(:Renderer)
          handler = Class.new do
            def initialize(app)
              @app = app
            end

            def call(args, id: nil)
              presentables = args[:presentables].each_with_object({}) { |presentable_info, presentable_hash|
                presentable_name, model_name, query_name, query_args = presentable_info.values_at(:name, :model_name, :query_name, :query_args)
                model = @app.data.public_send(model_name)
                data = model.public_send(query_name, *query_args)

                # NOTE: We go ahead and convert all data to an array, because the client can always
                # deal with this format, even if it only contains a single object.
                presentable_hash[presentable_name] = data.to_a
              }

              renderer = Renderer.new(@app, presentables)
              renderer.perform(args[:view_path])

              message = { transformation_id: args[:transformation_id], transformations: renderer.to_arr }
              @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, id), message)
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

            presentables = @__state.values

            metadata = {
              view_path: @presenter.class.path,
              transformation_id: @transformation_id,
              presentables: presentables.map { |presentable_name, presentable|
                {
                  name: presentable_name,
                  model_name: presentable.model.name,
                  query_name: presentable.name,
                  query_args: presentable.args
                }
              }
            }

            # Find every subscribed presentable, creating a data subscription for each.
            #
            queries = presentables.values.select { |presentable_value|
              presentable_value.is_a?(Data::Query)
            }

            queries.each do |presentable_query|
              if subscription_id = presentable_query.subscribe(socket_client_id, call: handler, with: metadata)
                app.data.expire(socket_client_id, SUBSCRIPTION_TIMEOUT)
                subscribe(:transformation, subscription_id)
              end
            end
          end
        end
      end
    end
  end
end
