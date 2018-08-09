# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  class App
    module Behavior
      # Loads default pipeline actions based on included frameworks.
      #
      module Pipeline
        extend Support::Extension

        apply_extension do
          after :initialize, priority: :low do
            load_pipeline_defaults
          end
        end

        private

        def load_pipeline_defaults
          if self.class.includes_framework?(:assets)
            @__pipeline.action(Assets::Actions::Public, self)
            @__pipeline.action(Assets::Actions::Process)
          end

          if self.class.includes_framework?(:core) && !Pakyow.env?(:prototype)
            state_for(:controller).each do |controller|
              @__pipeline.action(controller)
            end
          end

          if self.class.includes_framework?(:presenter)
            @__pipeline.action(Presenter::AutoRender)
          end

          if self.class.includes_framework?(:core) && !Pakyow.env?(:prototype)
            @__pipeline.action(Routing::RespondMissing, self)
          end
        end
      end
    end
  end
end
