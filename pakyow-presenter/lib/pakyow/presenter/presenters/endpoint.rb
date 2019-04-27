# frozen_string_literal: true

require "pakyow/presenter/presenter"
require "pakyow/presenter/presenters/form"

module Pakyow
  module Presenter
    module Presenters
      class Endpoint < DelegateClass(Presenter)
        def setup
          if endpoint_method == :delete
            setup_endpoint_for_removal(
              name: view.object.label(:endpoint),
              path: endpoint_path
            )
          else
            setup_endpoint(
              name: view.object.label(:endpoint),
              method: endpoint_method,
              path: endpoint_path
            )
          end
        end

        # Fixes an issue using pp inside a delegator.
        #
        def pp(*args)
          Kernel.pp(*args)
        end

        private

        def endpoint_method
          if view.object.labeled?(:endpoint_object)
            view.object.label(:endpoint_object).method
          else
            :get
          end
        end

        def endpoint_path
          if Pakyow.env?(:prototype)
            case view.object.tagname
            when "a"
              view.attrs[:href].to_s
            when "form"
              view.attrs[:action].to_s
            else
              nil
            end
          elsif view.object.labeled?(:endpoint_object)
            view.object.label(:endpoint_object).path(
              __endpoint.params.merge(view.object.label(:endpoint_params).to_h)
            )
          else
            nil
          end
        end

        def find_endpoint_action_node(endpoint_node)
          endpoint_node.find_first_significant_node_without_descending(
            :endpoint_action
          ) || endpoint_node
        end

        def setup_endpoint(name:, method:, path:)
          endpoint_action_view = View.from_object(find_endpoint_action_node(view.object))

          case endpoint_action_view.object.tagname
          when "a"
            if path && !Pakyow.env?(:prototype)
              endpoint_action_view.attributes[:href] = path
            end

            if endpoint_action_view.attributes.has?(:href)
              endpoint_path = __endpoint[:path].to_s
              if endpoint_path == endpoint_action_view.attributes[:href]
                view.attributes[:class].add(:current)
              elsif endpoint_path.start_with?(endpoint_action_view.attributes[:href])
                view.attributes[:class].add(:active)
              end
            end
          when "form"
            form_presenter = Form.new(__getobj__)
            form_presenter.action = path
            form_presenter.method = method
          end
        end

        def setup_endpoint_for_removal(name:, path:)
          if view.object.tagname == "form"
            form_presenter = Form.new(__getobj__)
            form_presenter.action = path
            form_presenter.method = :delete
            view.object.attributes[:"data-ui"] = "confirmable"
          else
            view.replace(
              View.new(
                <<~HTML
                  <form action="#{path}" method="post" data-ui="confirmable">
                    <input type="hidden" name="_method" value="delete">
                    #{view.object}
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
