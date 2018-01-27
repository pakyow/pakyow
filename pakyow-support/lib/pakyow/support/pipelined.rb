# frozen_string_literal: true

module Pakyow
  module Support
    module Pipelined
      def self.included(base)
        base.instance_variable_set(:@__pipeline, Pipeline.new)
        base.extend(ClassAPI)
      end

      module ClassAPI
        def include_pipeline_actions(actions)
          @__pipeline.include_actions(actions)
        end

        def pipeline
          @__pipeline
        end
      end

      class Pipeline
        attr_reader :actions

        def initialize
          @actions = []
        end

        def initialize_copy(_)
          @actions = @actions.dup
        end

        def call(*args, context: self)
          @actions.each do |action|
            if action.is_a?(Symbol)
              context.__send__(action, *args)
            else
              action.call(*args)
            end
          end
        end

        def action(action)
          include_actions([action])
        end

        def include_actions(actions)
          @actions.concat(actions).uniq!
        end

        def exclude_actions(actions)
          @actions = @actions - actions
        end

        def merge(other_pipeline)
          include_actions(other_pipeline.actions)
        end

        def exclude(other_pipeline)
          exclude_actions(other_pipeline.actions)
        end

        def clear
          @actions = []
        end
      end
    end
  end
end
