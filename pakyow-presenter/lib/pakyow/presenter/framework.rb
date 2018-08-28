# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/helpers/exposures"

require "pakyow/presenter/behavior/building"
require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/exposures"
require "pakyow/presenter/helpers/rendering"
require "pakyow/presenter/helpers/renderable"

require "pakyow/presenter/pipelines/implicit_rendering"

require "pakyow/presenter/rendering/component_renderer"
require "pakyow/presenter/rendering/view_renderer"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      def boot
        require "pakyow/presenter/presentable_error"

        app.class_eval do
          isolate(ComponentRenderer)
          isolate(ViewRenderer)

          stateful :templates, Templates
          stateful :presenter, Presenter
          stateful :component, isolate(Component)
          stateful :binder, Binder
          stateful :processor, Processor

          aspect :presenters
          aspect :components
          aspect :binders

          isolated :Connection do
            include Helpers::Renderable
          end

          isolated :Component do
            include Routing::Helpers::Exposures
            include Helpers::Exposures
          end

          isolated :Controller do
            include_pipeline Pipelines::ImplicitRendering

            # We don't load these as normal helpers because they should only be
            # available within controllers; not anywhere helpers are loaded.
            #
            include Helpers::Exposures
            include Helpers::Rendering
          end

          before :load do
            config.helpers.each do |helper|
              # Include other registered helpers into the view renderer.
              #
              isolated(:ViewRenderer).include helper

              # Include other registered helpers into the component and renderer.
              #
              isolated(:Component).include helper
              isolated(:ComponentRenderer).include helper
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
