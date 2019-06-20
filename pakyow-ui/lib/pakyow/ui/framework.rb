# frozen_string_literal: true

require "pakyow/framework"

require "pakyow/ui/helpers"

require "pakyow/ui/behavior/recording"
require "pakyow/ui/behavior/rendering"
require "pakyow/ui/behavior/timeouts"

require "pakyow/ui/behavior/rendering/install_transforms"

module Pakyow
  module UI
    class Framework < Pakyow::Framework(:ui)
      # @api private
      module PresenterForContext
        def presenter_for_context(presenter_class, context)
          if context.presentables.include?(:__ui_transform)
            instance = find_ui_presenter_for(presenter_class).new(
              context.view, app: context.app, presentables: context.presentables
            )

            instance.instance_variable_set(:@calls, context.calls)
            instance
          else
            super
          end
        end
      end

      def boot
        object.class_eval do
          register_helper :passive, Helpers

          include Behavior::Recording
          include Behavior::Rendering
          include Behavior::Timeouts

          isolated :Renderer do
            include Behavior::Rendering::InstallTransforms
          end

          prepend PresenterForContext

          ui_renderer = Class.new(isolated(:Renderer)) do
            def marshal_load(state)
              deserialize(state)
              @presenter_class = @app.find_ui_presenter_for(@presenter_class)
              initialize_presenter
            end

            def perform(*)
              @presenter.to_html
            end
          end

          # Delete the render_components build step since ui will not be invoking the component.
          #
          ui_renderer.__build_fns.delete_if { |fn|
            fn.source_location[0].end_with?("render_components.rb")
          }

          unless const_defined?(:UIRenderer, false)
            const_set(:UIRenderer, ui_renderer)
          end
        end
      end
    end
  end
end
