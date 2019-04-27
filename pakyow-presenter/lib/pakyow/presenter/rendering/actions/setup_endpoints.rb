# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/presenter/presenters/endpoint"

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
                setup
              end
            else
              presenter.render node: -> {
                object.find_significant_nodes(:endpoint).select { |node|
                  node.labeled?(:endpoint_object) && node.tagname != "form"
                }.map { |node|
                  View.from_object(node)
                }
              }, priority: :low do
                setup
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
