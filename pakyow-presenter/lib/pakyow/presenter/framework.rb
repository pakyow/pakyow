# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/support/indifferentize"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/application/config/presenter"
require "pakyow/application/behavior/presenter/error_rendering"
require "pakyow/application/behavior/presenter/exposures"
require "pakyow/application/behavior/presenter/implicit_rendering"
require "pakyow/application/behavior/presenter/initializing"
require "pakyow/application/behavior/presenter/modes"
require "pakyow/application/behavior/presenter/versions"
require "pakyow/application/behavior/presenter/watching"

require "pakyow/application/helpers/presenter/rendering"

require "pakyow/presenter/renderable"

require "pakyow/presenter/renderer"
require "pakyow/presenter/renderer/behavior/cleanup_prototype_nodes"
require "pakyow/presenter/renderer/behavior/cleanup_unbound_bindings"
require "pakyow/presenter/renderer/behavior/create_template_nodes"
require "pakyow/presenter/renderer/behavior/install_development_tools"
require "pakyow/presenter/renderer/behavior/install_authenticity"
require "pakyow/presenter/renderer/behavior/place_in_mode"
require "pakyow/presenter/renderer/behavior/render_components"
require "pakyow/presenter/renderer/behavior/set_page_title"
require "pakyow/presenter/renderer/behavior/setup_endpoints"
require "pakyow/presenter/renderer/behavior/setup_forms"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      using Support::Indifferentize
      using Support::Refinements::String::Normalization

      def boot
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
            include Renderer::Behavior::CleanupPrototypeNodes
            include Renderer::Behavior::CleanupUnboundBindings
            include Renderer::Behavior::InstallDevelopmentTools
            include Renderer::Behavior::InstallAuthenticity
            include Renderer::Behavior::PlaceInMode
            include Renderer::Behavior::CreateTemplateNodes
            include Renderer::Behavior::SetupEndpoints
            include Renderer::Behavior::SetupForms
            include Renderer::Behavior::SetPageTitle
          end

          after "load" do
            isolated(:Renderer) do
              include Renderer::Behavior::RenderComponents
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

          register_helper :active, Application::Helpers::Presenter::Rendering

          isolated :Connection do
            include Renderable
          end

          isolated :Controller do
            include Application::Behavior::Presenter::ImplicitRendering

            action :verify_form_metadata do
              if metadata = params[:"pw-form"]
                connection.set(
                  :__form,
                  JSON.parse(
                    connection.verifier.verify(metadata)
                  ).indifferentize
                )

                params.delete(:"pw-form")
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

          include Application::Config::Presenter
          include Application::Behavior::Presenter::ErrorRendering
          include Application::Behavior::Presenter::Exposures
          include Application::Behavior::Presenter::Initializing
          include Application::Behavior::Presenter::Modes
          include Application::Behavior::Presenter::Versions
          include Application::Behavior::Presenter::Watching

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
