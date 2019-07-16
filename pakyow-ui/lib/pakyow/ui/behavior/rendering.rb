# frozen_string_literal: true

require "securerandom"

require "pakyow/support/deep_dup"
require "pakyow/support/extension"
require "pakyow/support/inflector"

require "pakyow/realtime/helpers/subscriptions"

require "pakyow/ui/handler"

module Pakyow
  module UI
    module Behavior
      module Rendering
        extend Support::Extension

        apply_extension do
          isolated :Renderer do
            include Realtime::Helpers::Subscriptions

            # @api private
            def socket_client_id
              presentables[:__socket_client_id]
            end

            on "render" do
              unless presentables.include?(:__ui_transform) || subscribables.empty?
                # To keep up with the node(s) that matter for the transformation, a `data-t` attribute
                # is added to the node that contains the transformation_id. When the transformation is
                # triggered in the future, the client knows what node to apply tranformations to.
                #
                # Note that when we're presenting an entire view, `data-t` is set on the `html` node.
                #
                transformation_target = case @presenter.view.object
                when StringDoc
                  @presenter.view.object.find_first_significant_node(:html)
                when StringDoc::Node
                  @presenter.view.object
                end

                if transformation_target
                  ui_renderer_instance = @app.isolated(:UIRenderer).allocate

                  instance_variables.each do |ivar|
                    ui_renderer_instance.instance_variable_set(ivar, instance_variable_get(ivar))
                  end

                  metadata = {
                    renderer: ui_renderer_instance
                  }

                  @payload = {
                    metadata: Marshal.dump(metadata)
                  }

                  # Generate a unique id based on the value of the metadata. This guarantees that the
                  # transformation id will be consistent across subscriptions.
                  #
                  transformation_id = Digest::SHA1.hexdigest(@payload[:metadata])
                  presentables[:__transformation_id] = transformation_id
                  @payload[:transformation_id] = transformation_id
                  @payload[:id] = transformation_id
                end
              end
            end

            after "render" do
              if instance_variable_defined?(:@payload)
                @app.ui_executor.post(self, subscribables, @payload, Pakyow.logger.target) do |context, subscribables, payload, logger|
                  logger.internal {
                    "[ui] subscribing #{@payload[:id]}"
                  }

                  # Find every subscribable presentable, creating a data subscription for each.
                  #
                  subscribables.each do |subscribable|
                    subscribable.subscribe(context.socket_client_id, handler: Handler, payload: payload) do |ids|
                      # Subscribe the subscriptions to the "transformation" channel.
                      #
                      context.subscribe(:transformation, *ids.uniq)
                    end
                  end

                  # Expire subscriptions if the connection is never established.
                  #
                  context.app.data.expire(context.socket_client_id, context.app.config.realtime.timeouts.initial)
                end
              end
            end

            using Support::DeepDup

            private def subscribables
              @subscribables ||= presentables.reject { |presentable_name, _|
                presentable_name.to_s.start_with?("__")
              }.map { |_, value|
                proxy = if value.is_a?(Data::Proxy)
                  value
                elsif value.instance_variable_defined?(:@__proxy)
                  value.instance_variable_get(:@__proxy)
                else
                  nil
                end

                if proxy && proxy.subscribable?
                  proxy.deep_dup
                else
                  nil
                end
              }.compact.uniq { |subscribable|
                subscribable.source.__getobj__
              }
            end
          end
        end
      end
    end
  end
end
