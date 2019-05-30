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
              path: endpoint_path
            )
          else
            setup_endpoint(
              path: endpoint_path,
              method: endpoint_method
            )
          end
        end

        # Fixes an issue using pp inside a delegator.
        #
        def pp(*args)
          Kernel.pp(*args)
        end

        # Delegate private methods.
        #
        def method_missing(method_name, *args, &block)
          __getobj__.send(method_name, *args, &block)
        end

        def respond_to_missing?(method_name, include_private = false)
          super || __getobj__.respond_to?(method_name, true)
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

        def setup_endpoint(path:, method:)
          endpoint_action_presenter = endpoint_action
          case endpoint_action_presenter.object.tagname
          when "a"
            if path && !Pakyow.env?(:prototype)
              endpoint_action_presenter.attributes[:href] = path
            end

            if endpoint_action_presenter.attributes.has?(:href)
              endpoint_path = __endpoint[:path].to_s
              if endpoint_path == endpoint_action_presenter.attributes[:href]
                attributes[:class].add(:current)
              elsif endpoint_path.start_with?(endpoint_action_presenter.attributes[:href])
                attributes[:class].add(:active)
              end
            end
          when "form"
            form_presenter = Form.new(__getobj__)
            form_presenter.action = path
            form_presenter.method = method
          end
        end

        def setup_endpoint_for_removal(path:)
          if object.tagname == "form"
            form_presenter = presenter_for(__getobj__, type: Form)
            form_presenter.action = path
            form_presenter.method = :delete
            attributes[:"data-ui"] = "confirmable"
          else
            replace(
              View.new(
                <<~HTML
                  <form action="#{path}" method="post" data-ui="confirmable">
                    <input type="hidden" name="_method" value="delete">
                    #{view.object.render}
                  </form>
                HTML
              )
            )
          end
        end

        class << self
          # Recursively attach to binding endpoints.
          #
          # @api private
          def attach_to_node(node, renders, binding_path: [], channel: nil)
            node.each_significant_node(:binding) do |binding_node|
              next_binding_path = binding_path.dup
              if binding_node.significant?(:binding_within)
                next_binding_path << binding_node.label(:binding)
              end

              current_binding_path = binding_path.dup
              current_binding_path << binding_node.label(:binding)

              if binding_node.significant?(:endpoint)
                renders << {
                  binding_path: current_binding_path,
                  channel: channel,
                  priority: :low,
                  block: Proc.new {
                    setup
                  }
                }
              else
                binding_node.find_significant_nodes(:endpoint).each do |endpoint_node|
                  renders << {
                    binding_path: current_binding_path,
                    channel: channel,
                    priority: :low,
                    block: Proc.new {
                      endpoint(endpoint_node.label(:endpoint))&.setup
                    }
                  }
                end
              end

              attach_to_node(binding_node, renders, binding_path: next_binding_path, channel: channel)
            end
          end
        end
      end
    end
  end
end
