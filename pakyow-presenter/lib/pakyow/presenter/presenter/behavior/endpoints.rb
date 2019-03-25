# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/endpoints"

module Pakyow
  module Presenter
    class Presenter
      module Behavior
        module Endpoints
          extend Support::Extension

          prepend_methods do
            def initialize(view, endpoints: Pakyow::Endpoints.new, **kwargs)
              @endpoints = endpoints
              super(view, **kwargs)
            end

            # def bind(data)
            #   object = if data.is_a?(Binder)
            #     data.object
            #   else
            #     data
            #   end

            #   if object
            #     setup_binding_endpoints(object)
            #   end

            #   super.tap do
            #     if object && endpoint_state_defined?
            #       # Keep track of parent bindings / bound objects. We'll use these
            #       # later when setting up endpoints that rely on parent state.
            #       #
            #       (__endpoint.params[:__parent_bindings] ||= {})[view.binding_name] = object
            #     end
            #   end
            # end

            def presenter_for(*)
              super.tap do |presenter|
                presenter&.instance_variable_set(:@endpoints, @endpoints)
              end
            end

            # def wrap_data_in_binder(*)
            #   super.tap do |binder|
            #     if endpoint_state_defined?
            #       if binder_local_endpoints = @endpoints
            #         unless binder.respond_to?(:path)
            #           binder.define_singleton_method :path do |*args|
            #             binder_local_endpoints.path(*args)
            #           end
            #         end

            #         unless binder.respond_to?(:path_to)
            #           binder.define_singleton_method :path_to do |*args|
            #             binder_local_endpoints.path_to(*args)
            #           end
            #         end
            #       end
            #     end
            #   end
            # end
          end

          # @api private
          def setup_non_contextual_endpoints
            setup_endpoints(
              build_endpoints(
                within_binding: false
              )
            )
          end

          # @api private
          def setup_binding_endpoints(object)
            setup_endpoints(binding_endpoints(object))
          end

          private

          def endpoint_state_defined?
            respond_to?(:__endpoint)
          end

          def build_endpoints(passed_params = {}, nodes: nil, within_binding: nil)
            if endpoint_state_defined?
              # Build up all the endpoint state we have into a single value hash.
              #
              # FIXME: we could be smarter about this by asking @endpoints what
              # values it expects, then building up only what we need; endpoints
              # don't currently provide this knowledge
              params = __endpoint.params[:__parent_bindings].to_h.each_with_object(__endpoint.params.dup) { |(parent_binding, parent_object), merged_params|
                merged_params.merge!(Hash[parent_object.to_h.map { |key, value|
                  [:"#{parent_binding}_#{key}", value]
                }])
              }.merge(passed_params.respond_to?(:to_h) ? passed_params.to_h : {})
            end

            [].tap do |endpoints|
              if nodes
                nodes.each do |node|
                  build_endpoint_for_node(node, endpoints, params)
                end
              else
                @view.object.each_significant_node(:endpoint) do |node|
                  if (within_binding && node.significant?(:within_binding)) || (!within_binding && !node.significant?(:within_binding))
                    build_endpoint_for_node(node, endpoints, params)
                  end
                end
              end
            end
          end

          def binding_endpoints(object)
            if @view.object.is_a?(StringDoc::Node) && @view.object.significant?(:endpoint) && @view.object.significant?(:binding)
              build_endpoints(object, nodes: [@view.object])
            else
              build_endpoints(object, within_binding: true)
            end
          end

          def build_endpoint_for_node(node, endpoints, params)
            name = node.label(:endpoint)

            endpoints << {
              node: node,
              name: name,
              path: @endpoints.path(*name, **params.to_h),
              method: @endpoints.method(name)
            }
          end

          def setup_endpoints(endpoints)
            endpoints.each do |endpoint|
              if endpoint[:method] == :delete
                wrap_endpoint_for_removal(endpoint)
              else
                setup_endpoint(endpoint)
              end
            end
          end

          def wrap_endpoint_for_removal(endpoint)
            if endpoint[:node].tagname != "form"
              View.from_object(endpoint[:node]).replace(
                View.new(
                  <<~HTML
                    <form action="#{endpoint[:path]}" method="post" data-ui="confirmable">
                      <input type="hidden" name="_method" value="delete">

                      #{endpoint[:node]}
                    </form>
                  HTML
                )
              )
            end
          end

          def setup_endpoint(endpoint)
            endpoint_view = View.from_object(endpoint[:node])
            endpoint_action_view = View.from_object(find_endpoint_action_node(endpoint[:node]))

            if endpoint_action_view.object.tagname == "a"
              if endpoint[:path]
                endpoint_action_view.attributes[:href] = endpoint[:path]
              end

              if endpoint_action_view.attributes.has?(:href)
                endpoint_path = __endpoint[:path].to_s
                if endpoint_path == endpoint_action_view.attributes[:href]
                  endpoint_view.attributes[:class].add(:current)
                elsif endpoint_path.start_with?(endpoint_action_view.attributes[:href])
                  endpoint_view.attributes[:class].add(:active)
                end
              end
            end
          end

          def find_endpoint_action_node(endpoint_node)
            endpoint_node.find_first_significant_node_without_descending(
              :endpoint_action
            ) || endpoint_node
          end
        end
      end
    end
  end
end
