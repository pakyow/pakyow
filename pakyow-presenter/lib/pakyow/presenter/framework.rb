# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/support/indifferentize"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/exposures"
require "pakyow/presenter/behavior/implicit_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/modes"
require "pakyow/presenter/behavior/versions"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/rendering"

require "pakyow/presenter/renderable"

require "pakyow/presenter/renderer"

require "pakyow/presenter/rendering/actions/cleanup_prototype_nodes"
require "pakyow/presenter/rendering/actions/cleanup_unbound_bindings"
require "pakyow/presenter/rendering/actions/create_template_nodes"
require "pakyow/presenter/rendering/actions/insert_prototype_bar"
require "pakyow/presenter/rendering/actions/install_authenticity"
require "pakyow/presenter/rendering/actions/place_in_mode"
require "pakyow/presenter/rendering/actions/render_components"
require "pakyow/presenter/rendering/actions/set_page_title"
require "pakyow/presenter/rendering/actions/setup_endpoints"
require "pakyow/presenter/rendering/actions/setup_forms"
require "pakyow/presenter/rendering/actions/use_versions"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      using Support::Indifferentize
      using Support::Refinements::String::Normalization

      def boot
        require "pakyow/presenter/presentable_error"

        object.class_eval do
          isolate Binder
          isolate Presenter

          # Make sure component presenters inherit from this app's presenter.
          #
          isolated_presenter = isolated(:Presenter)
          isolate Component do
            @__presenter_class = isolated_presenter
          end

          isolate Renderer do
            include Actions::CleanupPrototypeNodes
            include Actions::CleanupUnboundBindings
            include Actions::CreateTemplateNodes
            include Actions::InsertPrototypeBar
            include Actions::InstallAuthenticity
            include Actions::PlaceInMode
            include Actions::SetupEndpoints
            include Actions::SetupForms
            include Actions::SetPageTitle
            include Actions::UseVersions
          end

          after "load" do
            isolated(:Renderer) do
              include Actions::RenderComponents
            end
          end

          # Build presenter classes for compound components.
          #
          after :initialize, priority: :high do
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
                      state(:presenter) << Actions::RenderComponents.find_or_build_compound_presenter(
                        self, component_classes
                      )
                    end
                  end
                end
              end
            end
          end

          def presenter_for_context(presenter_class, context)
            presenter_class.new(
              context.view, app: context.app, presentables: context.presentables
            )
          end

          stateful :binder,    isolated(:Binder)
          stateful :component, isolated(:Component)
          stateful :presenter, isolated(:Presenter)

          stateful :processor, Processor
          stateful :templates, Templates

          aspect :binders
          aspect :components
          aspect :presenters

          register_helper :active, Helpers::Rendering

          isolated :Connection do
            include Renderable
          end

          isolated :Controller do
            include Behavior::ImplicitRendering

            action :verify_form_metadata do
              if metadata = params[:_form]
                connection.set(
                  :__form,
                  JSON.parse(
                    connection.verifier.verify(metadata)
                  ).indifferentize
                )

                params.delete(:_form)
              end
            end
          end

          on "load" do
            self.class.include_helpers :global, isolated(:Binder)
            self.class.include_helpers :global, isolated(:Presenter)
            self.class.include_helpers :active, isolated(:Component)

            # Override the app helper so that config returns the component config.
            # FIXME: Find a clearer way to do this.
            #
            isolated(:Component) do
              if instance_methods(false).include?(:config)
                remove_method :config
              end

              attr_reader :config
            end
          end

          # Let each renderer action attach renders to the app's presenter.
          #
          after "initialize", priority: :low do
            [isolated(:Presenter)].concat(
              state(:presenter)
            ).concat(
              state(:component).map(&:__presenter_class)
            ).uniq.each do |presenter|
              isolated(:Renderer).attach!(presenter, app: self)
            end
          end

          # Update the presenter version and rebuild the app version.
          #
          after "initialize" do
            config.presenter.version = Support::PathVersion.build(config.presenter.path)

            app_version = Digest::SHA1.new
            app_version.update(config.version)
            app_version.update(config.presenter.version)
            config.version = app_version.to_s
          end

          include Behavior::Config
          include Behavior::ErrorRendering
          include Behavior::Exposures
          include Behavior::Initializing
          include Behavior::Modes
          include Behavior::Versions
          include Behavior::Watching

          def view_info_for_path(path)
            path = String.collapse_path(path)

            state(:templates).lazy.map { |store|
              store.info(path)
            }.find(&:itself)
          end

          def view?(path)
            !view_info_for_path(path).nil?
          end
        end
      end
    end
  end
end
