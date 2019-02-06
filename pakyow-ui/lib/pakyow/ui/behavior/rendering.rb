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

            action :subscribe_to_transformations
          end

          isolated :ViewRenderer do
            include Realtime::Helpers::Subscriptions
            include TransformationHelpers

            before :render do
              # Make sure these values are cached because they could change during presentation.
              #
              presentables; subscribables

              unless ui_transform? || subscribables.empty?
                # To keep up with the node(s) that matter for the transformation, a `data-t` attribute
                # is added to the node that contains the transformation_id. When the transformation is
                # triggered in the future, the client knows what node to apply tranformations to.
                #
                # Note that when we're presenting an entire view, `data-t` is set on the `html` node.
                #
                if node = @presenter.view.object.find_significant_nodes(:html)[0]
                  @transformation_target = node
                end
              end
            end

            action :subscribe_to_transformations
          end
        end

        module TransformationHelpers
          def transformation_target?
            instance_variable_defined?(:@transformation_target)
          end

          def presentables
            @presentables ||= @connection.values.reject { |presentable_name, _|
              presentable_name.to_s.start_with?("__")
            }.map { |presentable_name, presentable|
              proxy = if presentable.is_a?(Data::Proxy)
                presentable
              elsif presentable.instance_variable_defined?(:@__proxy)
                presentable.instance_variable_get(:@__proxy)
              else
                nil
              end

              if proxy
                proxy = proxy.deep_dup
                if proxy.source.is_a?(Data::Sources::Ephemeral)
                  { name: presentable_name, ephemeral: proxy.source.serialize }
                else
                  { name: presentable_name, proxy: proxy.to_h }
                end
              else
                { name: presentable_name, value: presentable.dup }
              end
            }
          end

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

          def subscribe_to_transformations
            unless ui_transform? || !transformation_target?
              metadata = {
                renderer: {
                  class_name: Support.inflector.demodulize(self.class),
                  serialized: serialize
                },
                presentables: presentables,
                env: @connection.env.each_with_object({}) { |(key, value), keep|
                  if ENV_KEYS.include?(key)
                    keep[key] = value
                  end
                }
              }

              # Generate a unique id based on the value of the metadata.
              #
              transformation_id = Digest::SHA1.hexdigest(Marshal.dump(metadata))
              metadata[:transformation_id] = transformation_id

              # Set the transformation_id on the target node so that transformations can be applied to the right place.
              #
              @transformation_target.attributes[:"data-t"] = transformation_id

              # Find every subscribable presentable, creating a data subscription for each.
              #
              subscribables.each do |subscribable|
                subscription_ids = subscribable.subscribe(
                  socket_client_id,
                  handler: Handler,
                  payload: metadata
                )

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
