# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Loads default pipeline actions based on included frameworks.
    #
    module Pipeline
      extend Support::Extension

      apply_extension do
        before :finalize do
          load_pipeline_defaults
        end
      end

      private

      def load_pipeline_defaults
        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
          state_for(:controller).each do |controller|
            @__pipeline.action(controller)
          end
        end

        if self.class.includes_framework?(:presenter) && !Pakyow.env?(:production)
          @__pipeline.action(Presenter::AutoRender)
        end

        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
          @__pipeline.action(Routing::RespondMissing, self)
        end
      end
    end
  end
end
