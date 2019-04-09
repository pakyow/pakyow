# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/helpers/exposures"

require "pakyow/support/indifferentize"

require "pakyow/presenter/behavior/building"
require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/implicit_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/exposures"
require "pakyow/presenter/helpers/rendering"

require "pakyow/presenter/renderable"

require "pakyow/presenter/renderer"
require "pakyow/presenter/view_builder"

require "pakyow/presenter/rendering/actions/cleanup_prototype_nodes"
require "pakyow/presenter/rendering/actions/cleanup_unused_nodes"
require "pakyow/presenter/rendering/actions/create_template_nodes"
require "pakyow/presenter/rendering/actions/insert_prototype_bar"
require "pakyow/presenter/rendering/actions/install_authenticity"
require "pakyow/presenter/rendering/actions/place_in_mode"
require "pakyow/presenter/rendering/actions/present_presentables"
require "pakyow/presenter/rendering/actions/set_page_title"
require "pakyow/presenter/rendering/actions/setup_endpoints"
require "pakyow/presenter/rendering/actions/setup_forms"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      using Support::Indifferentize

      def boot
        require "pakyow/presenter/presentable_error"

        object.class_eval do
          isolate Binder
          isolate Presenter do
            include Actions::InsertPrototypeBar::PresenterHelpers
            include Actions::SetupEndpoints::PresenterHelpers
          end

          # Make sure component presenters inherit from this app's presenter.
          #
          isolated_presenter = isolated(:Presenter)
          isolate Component do
            @__presenter_class = isolated_presenter
          end

          isolate Renderer do
            include Actions::CleanupPrototypeNodes
            include Actions::CleanupUnusedNodes
            include Actions::CreateTemplateNodes
            include Actions::InsertPrototypeBar
            include Actions::InstallAuthenticity
            include Actions::PlaceInMode
            include Actions::PresentPresentables
            include Actions::SetupEndpoints
            include Actions::SetPageTitle
            include Actions::SetupForms
          end

          isolate ViewBuilder

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

          before :load do
            self.class.include_helpers :global, isolated(:Binder)
            self.class.include_helpers :global, isolated(:Presenter)
            self.class.include_helpers :active, isolated(:Component)
            self.class.include_helpers :passive, isolated(:Renderer)
          end

          # Let each renderer action attach renders to the app's presenter.
          #
          after :initialize do
            [isolated(:Presenter)].concat(state(:presenter)).each do |presenter|
              isolated(:Renderer).attach!(presenter)
            end
          end

          include Behavior::Building
          include Behavior::Config
          include Behavior::ErrorRendering
          include Behavior::Initializing
          include Behavior::Watching
        end
      end
    end
  end
end
