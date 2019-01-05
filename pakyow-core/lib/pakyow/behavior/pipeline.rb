# frozen_string_literal: true

require "pakyow/support/extension"

require "pakyow/actions/logger"
require "pakyow/actions/normalizer"
require "pakyow/actions/request_parser"

module Pakyow
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
        unless is_a?(Plugin)
          @__pipeline.action(Actions::Logger, self)
          @__pipeline.action(Actions::Normalizer, self)
          @__pipeline.action(Actions::RequestParser, self)
        end

        if self.class.includes_framework?(:assets)
          @__pipeline.action(Assets::Actions::Public, self)
          @__pipeline.action(Assets::Actions::Process)
        end

        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype)
          state(:controller).each do |controller|
            @__pipeline.action(controller)
          end
        end

        if instance_variable_defined?(:@__plug_instances)
          @__plug_instances.each do |plug_instance|
            @__pipeline.action(plug_instance)
          end
        end

        if self.class.includes_framework?(:presenter)
          @__pipeline.action(Presenter::Actions::AutoRender)
        end

        if self.class.includes_framework?(:routing) && !Pakyow.env?(:prototype) && !is_a?(Plugin)
          @__pipeline.action(Routing::Actions::RespondMissing, self)
        end
      end
    end
  end
end
