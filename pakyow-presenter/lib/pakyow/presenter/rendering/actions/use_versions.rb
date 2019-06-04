# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module UseVersions
        extend Support::Extension

        def self.attach_to_view(view, renders, binding_path: [], channel: nil)
          if Pakyow.env?(:prototype)
            versioned_nodes = []

            view.binding_scopes(descend: false).each do |binding_scope_node|
              binding_scope_view = View.from_object(binding_scope_node)

              channel = binding_scope_node.label(:explicit_channel)
              channel = nil if channel.empty?

              current_binding_path = binding_path.dup.concat([binding_scope_node.label(:binding)])

              versioned_nodes << {
                binding_path: current_binding_path,
                channel: channel
              }

              binding_scope_view.binding_props(descend: false).each do |binding_prop_node|
                channel = binding_prop_node.label(:explicit_channel)
                channel = nil if channel.empty?

                versioned_nodes << {
                  binding_path: current_binding_path.dup.concat([binding_prop_node.label(:binding)]),
                  channel: channel
                }
              end

              # Descend into nested.
              #
              attach_to_view(
                binding_scope_view, renders, binding_path: current_binding_path, channel: channel
              )
            end

            versioned_nodes.uniq.each do |binding_render|
              renders << {
                binding_path: binding_render[:binding_path],
                channel: binding_render[:channel],
                priority: :low,
                block: Proc.new {
                  unless object.internal_nodes.any? { |node| node.labeled?(:versioned) }
                    if object.internal_nodes.all? { |node| node.labeled?(:version) && node.label(:version) != VersionedView::DEFAULT_VERSION }
                      use(object.internal_nodes.first.label(:version))
                    else
                      use(:default)
                    end
                  end
                }
              }
            end
          end
        end
      end
    end
  end
end
