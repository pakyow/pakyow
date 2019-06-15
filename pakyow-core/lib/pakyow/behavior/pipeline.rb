# frozen_string_literal: true

require "pakyow/support/extension"

module Pakyow
  module Behavior
    # Loads default pipeline actions based on included frameworks.
    #
    module Pipeline
      extend Support::Extension

      apply_extension do
        # We set the priority very low here in case initialize hooks in other frameworks define
        # state that should be loaded into the pipeline (e.g. controllers).
        #
        after "initialize", "initialize.pipeline", priority: -10 do
          self.class.__pipeline.dup.tap do |pipeline|
            load_pipeline_defaults(pipeline)
            @__pipeline = pipeline.callable(self)
          end
        end
      end

      private

      def load_pipeline_defaults(pipeline)
        if self.class.includes_framework?(:assets)
          pipeline.action(Assets::Actions::Public, self)
          pipeline.action(Assets::Actions::Process)
        end

        if self.class.includes_framework?(:realtime) && Pakyow.config.realtime.server && !is_a?(Plugin)
          pipeline.action(Realtime::Actions::Upgrader)
        end

        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
          state(:controller).each do |controller|
            pipeline.action(controller, self)
          end
        end

        if instance_variable_defined?(:@__plug_instances)
          @__plug_instances.each do |plug_instance|
            pipeline.action(plug_instance)
          end
        end

        if self.class.includes_framework?(:presenter)
          pipeline.action(Presenter::Actions::AutoRender)
        end

        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype) && !is_a?(Plugin)
          pipeline.action(Routing::Actions::RespondMissing)
        end
      end
    end
  end
end
