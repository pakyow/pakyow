# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
      def self.extended(base)
        base.instance_variable_set(:@__pipeline_actions, [])
        base.extend(ClassAPI)
      end

      def pipeline_name(name = nil)
        if name
          @pipeline_name = name
        else
          @pipeline_name
        end
      end

      def action(name)
        (@__pipeline_actions << name).uniq!
      end

      def actions
        @__pipeline_actions
      end

      module ClassAPI
        extend Support::ClassLevelState
        class_level_state :__pipeline_actions, default: []

        def included(base)
          if base.ancestors.include?(Pipelined)
            base.include_pipeline_actions(@__pipeline_actions)
          else
            raise StandardError, "Expected `#{base}' to have included `Pakyow::Pipelined'"
          end
        end
      end
    end
  end
end
