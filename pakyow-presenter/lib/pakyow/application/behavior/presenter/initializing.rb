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
            unless ancestors.include?(Plugin)
              after "initialize", "initialize.presenter", priority: :high do
                state(:templates) << Pakyow::Presenter::Templates.new(
                  :default,
                  config.presenter.path,
                  processor: Pakyow::Presenter::ProcessorCaller.new(
                    state(:processor).map { |processor|
                      processor.new(self)
                    }
                  )
                )

                state(:templates) << Pakyow::Presenter::Templates.new(:errors, File.join(File.expand_path("../../../../", __FILE__), "views", "errors"))
              end

              after "load.plugins" do
                # Load plugin frontend after the app so that app has priority.
                #
                @plugs.each(&:load_frontend)
              end
            end

            # Build presenter classes for compound components.
            #
            after "initialize", priority: :high do
              state(:templates).each do |templates|
                templates.each do |template|
                  template.object.each_significant_node(:component, descend: true) do |node|
                    if node.label(:components).count > 1
                      component_classes = node.label(:components).each_with_object([]) { |component_label, arr|
                        component_class = state(:component).find { |component|
                          component.__object_name.name == component_label[:name]
                        }

                        if component_class
                          arr << component_class
                        end
                      }

                      if component_classes.count > 1
                        state(:presenter) << Pakyow::Presenter::Renderer::Behavior::RenderComponents.find_or_build_compound_presenter(
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
