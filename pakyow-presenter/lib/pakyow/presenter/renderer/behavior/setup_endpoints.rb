# frozen_string_literal: true

require "pakyow/support/extension"

require_relative "../../presenters/endpoint"

module Pakyow
  module Presenter
    class Renderer
      module Behavior
        # @api private
        module SetupEndpoints
          extend Support::Extension

          apply_extension do
            build do |view, app:|
              view.object.find_significant_nodes(:endpoint, descend: true).each do |node|
                if (endpoint = app.endpoints.find(name: node.label(:endpoint)))
                  node.set_label(:endpoint_object, endpoint)
                  node.set_label(:endpoint_params, {})
                end
              end
            end

            attach do |presenter|
              if Pakyow.env?(:prototype)
                presenter.render node: -> {
                  object.find_significant_nodes(:endpoint, descend: true).map { |node|
                    View.from_object(node)
                  }
                }, priority: :low do
                  setup
                end
              else
                # Setup non-binding endpoints (binding endpoints are setup dynamically in presenter).
                #
                presenter.render node: -> {
                  nodes = []
                  nodes << object if object.is_a?(StringDoc::Node) && object.significant?(:endpoint)
                  nodes.concat(object.find_significant_nodes(:endpoint))
                  nodes.select { |node|
                    node.labeled?(:endpoint_object)
                  }.map { |node|
                    View.from_object(node)
                  }
                }, priority: :low do
                  case self
                  when Presenters::Form
                    Presenters::Endpoint.new(__getobj__).setup
                  when Presenters::Endpoint
                    setup
                  end
                end
              end
            end

            expose do |connection|
              connection.set(:__endpoint, connection.endpoint)
            end
          end
        end
      end
    end
  end
end
