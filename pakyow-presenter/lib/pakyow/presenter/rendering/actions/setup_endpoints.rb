# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Presenter
    module Actions
      module SetupEndpoints
        extend Support::Extension

        apply_extension do
          build do |app, view|
            view.object.find_significant_nodes(:endpoint).each do |node|
              if endpoint = app.endpoints.find(name: node.label(:endpoint))
                node.set_label(:endpoint_object, endpoint)
                node.set_label(:endpoint_params, {})
              end
            end
          end

          attach do |presenter|
            if Pakyow.env?(:prototype)
              presenter.render node: -> {
                object.find_significant_nodes(:endpoint).map { |node|
                  View.from_object(node)
                }
              }, priority: :low do
                setup_endpoint(
                  name: @view.object.label(:endpoint),
                  method: :get, path: @view.attrs[:href].to_s
                )
              end
            else
              presenter.render node: -> {
                object.find_significant_nodes(:endpoint).select { |node|
                  node.labeled?(:endpoint_object)
                }.map { |node|
                  View.from_object(node)
                }
              }, priority: :low do
                if @view.object.label(:endpoint_object).method == :delete
                  unless @view.object.tagname == "form"
                    wrap_endpoint_for_removal(
                      name: @view.object.label(:endpoint),
                      path: @view.object.label(:endpoint_object).path(
                        __endpoint.params.merge(@view.object.label(:endpoint_params))
                      )
                    )
                  end
                else
                  setup_endpoint(
                    name: @view.object.label(:endpoint),
                    method: @view.object.label(:endpoint_object).method,
                    path: @view.object.label(:endpoint_object).path(
                      __endpoint.params.merge(@view.object.label(:endpoint_params))
                    )
                  )
                end
              end
            end
          end

          expose do |connection|
            connection.set(:__endpoint, connection.endpoint)
          end
        end

        module PresenterHelpers
          # FIXME: we only have this method + signature because of how we need ui to behave; ideally
          # we could handle things on the ui using primitives instead of having to implement this
          #
          private def setup_endpoint(name:, method:, path:)
            endpoint_action_view = View.from_object(find_endpoint_action_node(@view.object))

            # FIXME: in this new structure it may make more sense to handle form endpoints from here
            #
            if endpoint_action_view.object.tagname == "a"
              if path && !Pakyow.env?(:prototype)
                endpoint_action_view.attributes[:href] = path
              end

              if endpoint_action_view.attributes.has?(:href)
                endpoint_path = __endpoint[:path].to_s
                if endpoint_path == endpoint_action_view.attributes[:href]
                  @view.attributes[:class].add(:current)
                elsif endpoint_path.start_with?(endpoint_action_view.attributes[:href])
                  @view.attributes[:class].add(:active)
                end
              end
            end
          end

          private def find_endpoint_action_node(endpoint_node)
            endpoint_node.find_first_significant_node_without_descending(
              :endpoint_action
            ) || endpoint_node
          end

          # FIXME: we only have this method + signature because of how we need ui to behave; ideally
          # we could handle things on the ui using primitives instead of having to implement this
          #
          def wrap_endpoint_for_removal(name:, path:)
            @view.replace(
              View.new(
                <<~HTML
                  <form action="#{path}" method="post" data-ui="confirmable">
                    <input type="hidden" name="_method" value="delete">
                    #{@view.object}
                  </form>
                HTML
              )
            )
          end
        end
      end
    end
  end
end
