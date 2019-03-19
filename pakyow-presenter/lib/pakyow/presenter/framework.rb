# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/routing/helpers/exposures"

require "pakyow/support/indifferentize"

require "pakyow/presenter/behavior/authenticity_rendering"
require "pakyow/presenter/behavior/building"
require "pakyow/presenter/behavior/componentize"
require "pakyow/presenter/behavior/config"
require "pakyow/presenter/behavior/error_rendering"
require "pakyow/presenter/behavior/implicit_rendering"
require "pakyow/presenter/behavior/initializing"
require "pakyow/presenter/behavior/watching"

require "pakyow/presenter/helpers/exposures"
require "pakyow/presenter/helpers/rendering"

require "pakyow/presenter/renderable"

require "pakyow/presenter/rendering/component_renderer"
require "pakyow/presenter/rendering/view_renderer"

module Pakyow
  module Presenter
    class Framework < Pakyow::Framework(:presenter)
      using Support::Indifferentize

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

          isolate ComponentRenderer

          isolate ViewRenderer do
            include Behavior::AuthenticityRendering
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

          before :load do
            self.class.include_helpers :global, isolated(:Binder)
            self.class.include_helpers :global, isolated(:Presenter)
            self.class.include_helpers :active, isolated(:Component)
            self.class.include_helpers :passive, isolated(:ComponentRenderer)
            self.class.include_helpers :passive, isolated(:ViewRenderer)
          end

          include Behavior::Building
          include Behavior::Componentize
          include Behavior::Config
          include Behavior::ErrorRendering
          include Behavior::Initializing
          include Behavior::Watching
        end
      end
    end
  end
end
