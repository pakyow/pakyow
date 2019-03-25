# frozen_string_literal: true

require "pakyow/support/pipeline"

module Pakyow
  module Presenter
    class ViewBuilder
      include Support::Pipeline

      action :componentize_forms do |state|
        if state.app.config.presenter.componentize
          state.view.object.each_significant_node(:form) do |form|
            form.instance_variable_get(:@significance) << :component
            form.attributes[:"data-ui"] = :form
            form.set_label(:component, :form)
          end
        end
      end

      action :componentize_navigator do |state|
        if state.app.config.presenter.componentize
          if html = state.view.object.find_first_significant_node(:html)
            html.instance_variable_get(:@significance) << :component
            html.attributes[:"data-ui"] = :navigable
            html.set_label(:component, :navigable)
          end
        end
      end

      action :initialize_renderable_components

      private def initialize_renderable_components(state, view = state.view)
        view.components.each do |component_view|
          # If view will be rendered from the app, look for the component on the app.
          #
          component_state = if state.app.is_a?(Plugin) && state.app.app.view?(state.path)
            state.app.app.state(:component)
          else
            state.app.state(:component)
          end

          component_class = component_state.find { |component|
            component.__object_name.name == component_view.object.label(:component)
          }

          if component_class
            component_view.object.instance_variable_get(:@significance) << :renderable_component
            component_view.object.set_label(:component_class, component_class)
          end

          initialize_renderable_components(state, component_view)
        end
      end
    end
  end
end
