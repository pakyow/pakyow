# frozen_string_literal: true

require "json"
require "digest"

require "pakyow/core/framework"

require "pakyow/ui/helpers"
require "pakyow/ui/renderer"

require "pakyow/ui/behavior/recording"

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

      # Values we want to serialize from the rack env.
      #
      ENV_KEYS = %w(
        SCRIPT_NAME
        QUERY_STRING
        SERVER_PROTOCOL
        SERVER_SOFTWARE
        GATEWAY_INTERFACE
        REQUEST_METHOD
        REQUEST_PATH
        REQUEST_URI
        HTTP_VERSION
        HTTP_HOST
        HTTP_CACHE_CONTROL
        HTTP_UPGRADE_INSECURE_REQUESTS
        HTTP_USER_AGENT
        HTTP_ACCEPT
        HTTP_REFERER
        HTTP_ACCEPT_ENCODING
        HTTP_ACCEPT_LANGUAGE
        HTTP_COOKIE
        HTTP_X_FORWARDED_HOST
        HTTP_CONNECTION
        CONTENT_LENGTH
        SERVER_NAME
        SERVER_PORT
        PATH_INFO
        REMOTE_ADDR
        rack.request.query_string
        rack.request.query_hash
        pakyow.endpoint
      ).freeze

      def boot
        app.helper Helpers

        app.on :join do
          @connection.app.data.persist(@id)
        end

        app.on :leave do
          @connection.app.data.expire(@id, SUBSCRIPTION_TIMEOUT)
        end

        # Create subclasses of each presenter, then make the subclasses recordable.
        # These subclasses will be used when performing a ui presentation instead
        # of the original presenter, but they'll behave identically!
        #
        app.after :initialize do
          @ui_presenters = [Pakyow::Presenter::Presenter].concat(
            state_for(:presenter)
          ).map { |presenter_class|
            Class.new(presenter_class).tap do |subclass|
              subclass.include Behavior::Recording
            end
          }
        end

        app.class_eval do
          attr_reader :ui_presenters
        end

        if app.const_defined?(:Renderer)
          handler = Class.new do
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

              connection = Connection.new(@app, env)
              connection.instance_variable_set(:@values, presentables)

              renderer = Renderer.new(
                connection,
                as: args[:as],
                path: args[:path],
                layout: args[:layout],
                mode: args[:mode]
              )

              renderer.presenter.call(renderer.presenter)

              message = { id: args[:transformation_id], calls: renderer.presenter }
              @app.websocket_server.subscription_broadcast(Realtime::Channel.new(:transformation, subscription[:id]), message)
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

            if node = @presenter.view.object.find_significant_nodes(:html)[0]
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
              as: @as,
              path: @path,
              layout: @layout,
              mode: @mode,
              transformation_id: @transformation_id,
              presentables: presentables.map { |presentable_name, presentable|
                { name: presentable_name, proxy: presentable.to_h }
              },
              env: @connection.env.each_with_object({}) { |(key, value), keep|
                if ENV_KEYS.include?(key)
                  keep[key] = value
                end
              }
            }

            # Find every subscribable presentable, creating a data subscription for each.
            #
            presentables.values.select(&:subscribable?).each do |subscribable|
              subscription_ids = subscribable.subscribe(socket_client_id, handler: handler, payload: metadata)

              # Subscribe the subscriptions to the "transformation" channel.
              #
              subscribe(:transformation, *subscription_ids)
            end

            # Set the subscriptions we just created to expire if the connection is never established.
            #
            @connection.app.data.expire(socket_client_id, SUBSCRIPTION_TIMEOUT)
          end
        end
      end
    end
  end
end
