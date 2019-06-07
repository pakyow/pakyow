# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/helpers/exposures"

require "pakyow/support/indifferentize"
require "pakyow/support/core_refinements/string/normalization"

require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/implicit_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/exposures"
require "pakyow/presenter/helpers/rendering"

require "pakyow/presenter/renderable"

require "pakyow/presenter/renderer"

require "pakyow/presenter/rendering/actions/componentize"
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
            include Actions::Componentize
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

          stateful :binder,    isolated(:Binder)
          stateful :component, isolated(:Component)
          stateful :presenter, isolated(:Presenter)

          stateful :processor, Processor
          stateful :templates, Templates

          aspect :binders
          aspect :components
          aspect :presenters

          register_helper :active, Helpers::Exposures
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

          include Behavior::Config
          include Behavior::ErrorRendering
          include Behavior::Initializing
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
