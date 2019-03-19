# frozen_string_literal: true

require "securerandom"

require "pakyow/support/deep_dup"
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

        using Support::DeepDup

        # Values we want to serialize from the rack env.
        #
        ENV_KEYS = %w(
          rack.request.query_string
          rack.request.query_hash
          pakyow.endpoint.path
          pakyow.endpoint.name
        ).freeze

        apply_extension do
          isolated :ComponentRenderer do
            include Realtime::Helpers::Subscriptions
            include TransformationHelpers

            before :render do
              unless ui_transform? || subscribables.empty?
                @transformation_target = @presenter.view.object
              end
            end

            # action :cache_presentables, before: @__pipeline.actions.first
            action :subscribe_to_transformations, before: @__pipeline.actions.first
          end

          isolated :ViewRenderer do
            include Realtime::Helpers::Subscriptions
            include TransformationHelpers

            before :render do
              unless ui_transform? || subscribables.empty?
                # To keep up with the node(s) that matter for the transformation, a `data-t` attribute
                # is added to the node that contains the transformation_id. When the transformation is
                # triggered in the future, the client knows what node to apply tranformations to.
                #
                # Note that when we're presenting an entire view, `data-t` is set on the `html` node.
                #
                if node = @presenter.view.object.find_first_significant_node(:html)
                  @transformation_target = node
                end
              end
            end

            # action :cache_presentables, before: @__pipeline.actions.first
            action :subscribe_to_transformations, before: @__pipeline.actions.first
          end
        end

        module TransformationHelpers
          def transformation_target?
            instance_variable_defined?(:@transformation_target)
          end

          # Make sure these values are cached first because they could change during presentation.
          #
          # def cache_presentables
          #   presentables; subscribables
          # end

          # def presentables
          #   @presentables ||= @connection.values.reject { |presentable_name, _|
          #     presentable_name.to_s.start_with?("__")
          #   }.map { |presentable_name, presentable|
          #     proxy = if presentable.is_a?(Data::Proxy)
          #       presentable
          #     elsif presentable.instance_variable_defined?(:@__proxy)
          #       presentable.instance_variable_get(:@__proxy)
          #     else
          #       nil
          #     end

          #     if proxy
          #       proxy = proxy.deep_dup
          #       if proxy.source.is_a?(Data::Sources::Ephemeral)
          #         { name: presentable_name, ephemeral: proxy.source.serialize }
          #       else
          #         { name: presentable_name, proxy: proxy.to_h }
          #       end
          #     else
          #       { name: presentable_name, value: presentable.dup }
          #     end
          #   }
          # end

          def subscribables
            @subscribables ||= @connection.values.reject { |value_name, _|
              value_name.to_s.start_with?("__")
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
            }.compact
          end

          def subscribe_to_transformations(transformation_id = nil)
            unless transformation_id.is_a?(String)
              transformation_id = nil
            end

            if !ui_transform? && (transformation_target? || transformation_id)
              metadata = {
                renderer: {
                  class_name: Support.inflector.demodulize(self.class),
                  # TODO: use marshal instead of a custom serialization strategy
                  serialized: serialize
                },
                # presentables: presentables,
                # TODO: can we just serialize all connection values?
                #   how can we do this cleanly without special logic around data proxies?
                #   values should respond to serialize, or used raw? (then deserialize)
                # TODO: instead of caching presentables, why not subscribe first?
                #   if rendering fails, do we really want subscribables? yeah that'll work
                connection: Marshal.dump(@connection)
              }

              payload = {
                metadata: Marshal.dump(metadata)
              }

              # Generate a unique id based on the value of the metadata. This guarantees that the
              # transformation id will be consistent across subscriptions.
              #
              transformation_id ||= Digest::SHA1.hexdigest(payload[:metadata])
              payload[:transformation_id] = transformation_id
              @transformation_id = transformation_id

              # Set the transformation_id on the target node so that transformations can be applied to the right place.
              #
              if transformation_target?
                @transformation_target.attributes[:"data-t"] = transformation_id
              end

              # Find every subscribable presentable, creating a data subscription for each.
              #
              subscribables.each do |subscribable|
                subscribable.subscribe(socket_client_id, handler: Handler, payload: payload) do |ids|
                  # Subscribe the subscriptions to the "transformation" channel.
                  #
                  subscribe(:transformation, *ids)
                end
              end
            end
          end
        end
      end
    end
  end
end
