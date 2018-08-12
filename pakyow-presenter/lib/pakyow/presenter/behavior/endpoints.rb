# frozen_string_literal: true

require "pakyow/support/deep_dup"
require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Behavior
      module Endpoints
        using Support::DeepDup

        extend Support::Extension

        def install_endpoints(endpoints, current_endpoint:, setup_for_bindings: false)
          @endpoints = endpoints

          @current_endpoint = current_endpoint.dup.tap do |duped_endpoint|
            duped_endpoint.params = duped_endpoint.params.to_h.deep_dup
          end

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
                  unless binder.respond_to?(:path)
                    binder.define_singleton_method :path do |*args|
                      binder_local_endpoints.path(*args)
                    end
                  end

                  unless binder.respond_to?(:path_to)
                    binder.define_singleton_method :path_to do |*args|
                      binder_local_endpoints.path_to(*args)
                    end
                  end
                end
              end
            end
          end
        end

        # @api private
        def binding_endpoints(object)
          nodes = if @view.object.is_a?(StringNode) && @view.object.significant?(:endpoint) && @view.object.significant?(:binding)
            [@view.object]
          else
            @view.object.find_significant_nodes(:endpoint).select { |node|
              node.significant?(:within_binding)
            }
          end

          build_endpoints(nodes, object)
        end

        private

        def endpoint_state_defined?
          instance_variable_defined?(:@endpoints)
        end

        def build_endpoints(nodes, passed_params = {})
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
            }.merge(passed_params.respond_to?(:to_h) ? passed_params.to_h : {})
          end

          nodes.each_with_object([]) { |node, endpoints|
            name = node.label(:endpoint)

            endpoints << {
              node: node,
              name: name,
              path: @endpoints.path(*name, **params.to_h)
            }
          }
        end

        def setup_non_contextual_endpoints
          setup_endpoints(
            build_endpoints(
              @view.object.find_significant_nodes(:endpoint).reject { |node|
                node.significant?(:within_binding)
              }
            )
          )
        end

        def setup_binding_endpoints(object)
          setup_endpoints(binding_endpoints(object))
        end

        def setup_endpoints(endpoints)
          endpoints.each do |endpoint|
            if endpoint[:name].to_s.end_with?("delete")
              wrap_endpoint_for_removal(endpoint)
            else
              setup_endpoint(endpoint)
            end
          end
        end

        def wrap_endpoint_for_removal(endpoint)
          View.from_object(endpoint[:node]).replace(
            View.new(
              <<~HTML
                <form action="#{endpoint[:path]}" method="post" data-ui="confirm">
                  <input type="hidden" name="_method" value="delete">

                  #{endpoint[:node]}
                </form>
              HTML
            )
          )
        end

        def setup_endpoint(endpoint)
          endpoint_view = View.from_object(endpoint[:node])
          endpoint_action_view = View.from_object(find_endpoint_action_node(endpoint[:node]))

          if endpoint_action_view.object.tagname == "a"
            if endpoint[:path]
              endpoint_action_view.attributes[:href] = endpoint[:path]
            end

            if endpoint_action_view.attributes.has?(:href)
              endpoint_path = @current_endpoint[:path].to_s
              if endpoint_path == endpoint_action_view.attributes[:href]
                endpoint_view.attributes[:class].add(:current)
              elsif endpoint_path.start_with?(endpoint_action_view.attributes[:href])
                endpoint_view.attributes[:class].add(:active)
              end
            end
          end
        end

        def find_endpoint_action_node(endpoint_node)
          if action_node = endpoint_node.find_significant_nodes_without_descending(:endpoint_action)[0]
            action_node
          else
            endpoint_node
          end
        end
      end
    end
  end
end
