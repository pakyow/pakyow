# frozen_string_literal: true

require "securerandom"

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
          isolated :ComponentRenderer do
            include Realtime::Helpers::Subscriptions
            include TransformationHelpers

            before :render do
              unless ui_transform? || subscribables.empty?
                @transformation_target = @presenter.view.object
              end
            end

            after :render do
              subscribe_to_transformations
            end
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
                if node = @presenter.view.object.find_significant_nodes(:html)[0]
                  @transformation_target = node
                end
              end
            end

            after :render do
              subscribe_to_transformations
            end
          end
        end

        module TransformationHelpers
          def transformation_target?
            instance_variable_defined?(:@transformation_target)
          end

          def presentables
            @presentables ||= @connection.values.select { |_, presentable|
              presentable.is_a?(Data::Proxy)
            }
          end

          def subscribables
            @subscribables ||= presentables.values.select(&:subscribable?)
          end

          def subscribe_to_transformations
            unless ui_transform? || !transformation_target?
              metadata = {
                renderer: {
                  class_name: Support.inflector.demodulize(self.class),
                  serialized: serialize
                },
                presentables: presentables.map { |presentable_name, presentable|
                  { name: presentable_name, proxy: presentable.to_h }
                },
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
