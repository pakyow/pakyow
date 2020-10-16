# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/plugin"

module Pakyow
  class Application
    module Behavior
      module Presenter
        module Initializing
          extend Support::Extension

          apply_extension do
            if ancestors.include?(Plugin)
              after "load", "load.presenter" do
                load_frontend
              end
            else
              after "load", "load.presenter" do
                templates_config = {
                  paths: {
                    layouts: [
                      "layouts"
                    ],
                    pages: [
                      "pages"
                    ],
                    partials: [
                      "includes"
                    ]
                  }
                }

                if Pakyow.multiapp?
                  templates_config.dig(:paths, :layouts) << Pathname.new(Pakyow.config.common_frontend_path).join("layouts")
                  templates_config.dig(:paths, :pages) << Pathname.new(Pakyow.config.common_frontend_path).join("pages")
                  templates_config.dig(:paths, :partials) << Pathname.new(Pakyow.config.common_frontend_path).join("includes")
                end

                templates << Pakyow::Presenter::Templates.new(
                  :default,
                  config.presenter.path,
                  processor: Pakyow::Presenter::ProcessorCaller.new(
                    processors.each.map { |processor|
                      processor.new(self)
                    }
                  ),
                  config: templates_config
                )
              end
            end

            # Build presenter classes for compound components.
            #
            after "load.presenter" do
              templates.each do |template_definitions|
                template_definitions.each do |template|
                  template.object.each_significant_node(:component, descend: true) do |node|
                    if node.label(:components).count > 1
                      component_classes = node.label(:components).each_with_object([]) { |component_label, arr|
                        component_class = components.each.find { |component|
                          component.object_name.name == component_label[:name]
                        }

                        if component_class
                          arr << component_class
                        end
                      }

                      if component_classes.count > 1
                        presenters << Pakyow::Presenter::Renderer::Behavior::RenderComponents.find_or_build_compound_presenter(
                          self, component_classes
                        )
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
