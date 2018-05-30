# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Endpoints
        extend Support::Extension

        def install_endpoints(endpoints, current_endpoint:, setup_for_bindings: false)
          @endpoints, @current_endpoint = endpoints, current_endpoint

          setup_non_contextual_endpoints
          if setup_for_bindings
            setup_binding_endpoints({})
          end
        end

        prepend_methods do
          def bind(data)
            object = if data.is_a?(Binder)
              data.object
            else
              data
            end

            if object
              setup_binding_endpoints(object)
            end

            super.tap do
              if object && endpoint_state_defined?
                # Keep track of parent bindings / bound objects. We'll use these
                # later when setting up endpoints that rely on parent state.
                #
                (@current_endpoint.params[:__parent_bindings] ||= {})[view.binding_name] = object
              end
            end
          end

          def presenter_for(*)
            super.tap do |presenter|
              if endpoint_state_defined?
                presenter.install_endpoints(
                  @endpoints,
                  current_endpoint: @current_endpoint
                )
              end
            end
          end

          def wrap_data_in_binder(*)
            super.tap do |binder|
              if endpoint_state_defined?
                if binder_local_endpoints = @endpoints
                  binder.define_singleton_method :path do |*args|
                    binder_local_endpoints.path(*args)
                  end

                  binder.define_singleton_method :path_to do |*args|
                    binder_local_endpoints.path_to(*args)
                  end
                end
              end
            end
          end
        end

        private

        def endpoint_state_defined?
          instance_variable_defined?(:@endpoints)
        end

        def setup_non_contextual_endpoints
          setup_endpoints(
            @view.object.find_significant_nodes(:endpoint).reject { |node|
              node.significant?(:within_binding)
            })
        end

        def setup_binding_endpoints(object)
          nodes = if @view.object.is_a?(StringNode) && @view.object.significant?(:endpoint) && @view.object.significant?(:binding)
            [@view.object]
          else
            @view.object.find_significant_nodes(:endpoint).select { |node|
              node.significant?(:within_binding)
            }
          end

          setup_endpoints(nodes, object)
        end

        def setup_endpoints(nodes, params = {})
          if endpoint_state_defined?
            # Build up all the endpoint state we have into a single value hash.
            #
            # FIXME: we could be smarter about this by asking @endpoints what
            # values it expects, then building up only what we need; endpoints
            # don't currently provide this knowledge
            params = @current_endpoint.params[:__parent_bindings].to_h.each_with_object(@current_endpoint.params.dup) { |(parent_binding, parent_object), merged_params|
              merged_params.merge!(Hash[parent_object.to_h.map { |key, value|
                [:"#{parent_binding}_#{key}", value]
              }])
            }.merge(params.to_h)
          end

          nodes.each do |endpoint_node|
            endpoint_view = View.from_object(endpoint_node)
            endpoint_string = endpoint_node.label(:endpoint).to_s

            endpoint_action_node = find_endpoint_action_node(endpoint_node)

            if endpoint_string.end_with?("delete")
              wrap_endpoint_for_removal(endpoint_view, endpoint_string, params)
            elsif endpoint_action_node.tagname == "a"
              setup_endpoint_for_anchor(endpoint_view, View.from_object(endpoint_action_node), endpoint_string, params)
            end
          end
        end

        def wrap_endpoint_for_removal(endpoint_view, endpoint_string, params)
          delete_form = View.new(
            <<~HTML
              <form action="#{@endpoints&.path(*endpoint_string, params)}" method="post" data-ui="confirm">
                <input type="hidden" name="_method" value="delete">

                #{endpoint_view}
              </form>
              HTML
          )

          endpoint_view.replace(delete_form)
        end

        def setup_endpoint_for_anchor(endpoint_view, endpoint_action_view, endpoint_string, params)
          if path = @endpoints.path(*endpoint_string, **params.to_h)
            endpoint_action_view.attributes[:href] = path
          end

          if endpoint_action_view.attributes.has?(:href) && @current_endpoint[:path].to_s.start_with?(endpoint_action_view.attributes[:href])
            endpoint_view.attributes[:class].add(:active)
          end
        end

        def find_endpoint_action_node(endpoint_node)
          if action_node = endpoint_node.find_significant_nodes(:endpoint_action, with_children: false)[0]
            action_node
          else
            endpoint_node
          end
        end
      end
    end
  end
end
