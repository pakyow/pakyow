# frozen_string_literal: true

require "digest"

require "pakyow/support/extension"
require "pakyow/support/inflector"

require "pakyow/realtime/helpers/subscriptions"

require "pakyow/ui/handler"
require "pakyow/ui/wrappable"

module Pakyow
  module UI
    module Behavior
      module Rendering
        extend Support::Extension

        # Values we want to serialize from the rack env.
        #
        ENV_KEYS = %w(
          rack.request.query_string
          rack.request.query_hash
          pakyow.endpoint
        ).freeze

        apply_extension do
          subclass :Renderer do
            include Realtime::Helpers::Subscriptions

            before :render do
              unless self.class.ancestors.include?(Wrappable)
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
            end

            after :render do
              unless self.class.ancestors.include?(Wrappable)
                # We wait until after render so that we don't create subscriptions unnecessarily
                # in the event that something blew up during the render process.
                #
                presentables = @connection.values.select { |_, presentable|
                  presentable.is_a?(Data::Proxy)
                }

                metadata = {
                  renderer: {
                    class_name: Support.inflector.demodulize(self.class),
                    serialized: serialize
                  },
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
                  subscription_ids = subscribable.subscribe(socket_client_id, handler: Handler, payload: metadata)

                  # Subscribe the subscriptions to the "transformation" channel.
                  #
                  subscribe(:transformation, *subscription_ids)
                end
              end
            end
          end
        end
      end
    end
  end
end
