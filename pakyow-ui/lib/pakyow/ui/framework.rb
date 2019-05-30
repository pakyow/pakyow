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
      def boot
        object.class_eval do
          register_helper :passive, Helpers

          include Behavior::Recording
          include Behavior::Rendering
          include Behavior::Timeouts

          isolated :Renderer do
            include Behavior::Rendering::InstallTransforms
          end

          ui_renderer = Class.new(isolated(:Renderer)) do
            def marshal_load(state)
              deserialize(state)

              @presenter_class = @app.ui_presenters.find { |klass|
                klass.ancestors.include?(@presenter_class)
              }

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

          const_set(:UIRenderer, ui_renderer)
        end
      end
    end
  end
end
