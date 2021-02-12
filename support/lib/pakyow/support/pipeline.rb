# frozen_string_literal: true

require_relative "class_state"
require_relative "extension"
require_relative "system"

module Pakyow
  module Support
    # Pipelines define actions that are performed in order on an instance of the pipelined object.
    # Each action can act on the arguments passed to it. Any action can halt the pipeline, causing
    # the result to be immediately returned without calling other actions.
    #
    # @example
    #   class Application
    #     include Pakyow::Support::Pipeline
    #
    #     action :foo do |result|
    #       result << "foo"
    #     end
    #
    #     action :bar do |result|
    #       result << "bar"
    #
    #       halt result
    #     end
    #
    #     action :baz do |result|
    #       result << "baz"
    #     end
    #   end
    #
    #   Application.new.call([])
    #   => ["foo", "bar"]
    #
    module Pipeline
      require "pakyow/support/pipeline/action"
      require "pakyow/support/pipeline/extension"
      require "pakyow/support/pipeline/internal"

      extend Support::Extension

      extend_dependency ClassState

      # @api private
      attr_reader :__pipeline

      def initialize_copy(_)
        @__pipeline = @__pipeline.dup

        super
      end

      def reject(value = nil)
        throw :reject, value
      end

      def halt(value = nil)
        throw :halt, value
      end

      apply_extension do
        class_state :__pipelines, default: {}, inheritable: true
        class_state :__pipeline, default: Internal.new(self), inheritable: true

        # Define a default pipeline.
        #
        pipeline(:default) {}

        # Use the default pipeline so that actions can be defined immediately without ceremony.
        #
        use_pipeline :default
      end

      prepend_methods do
        if System.ruby_version < "2.7.0"
          def initialize(*)
            __common_pipeline_initialize
            super
          end
        else
          def initialize(*, **)
            __common_pipeline_initialize
            super
          end
        end

        private def __common_pipeline_initialize
          @__pipeline = self.class.__pipeline.dup
        end
      end

      class_methods do
        # Defines a pipeline.
        #
        def pipeline(name, &block)
          @__pipelines[name.to_sym] = Internal.new(self, &block)
        end

        # Uses a pipeline.
        #
        def use_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          include name_or_pipeline if name_or_pipeline.is_a?(Pipeline::Extension)
          @__pipeline = pipeline
        end

        # Includes actions into the current pipeline.
        #
        def include_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          include name_or_pipeline if name_or_pipeline.is_a?(Pipeline::Extension)
          @__pipeline.include_actions(pipeline.actions)
        end

        # Excludes actions from the current pipeline.
        #
        def exclude_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          @__pipeline.exclude_actions(pipeline.actions)
        end

        def skip(*actions)
          @__pipeline.skip(*actions)
        end

        def inherited(subclass)
          super

          subclass.__pipeline.reset(subclass)
        end

        private def find_pipeline(name_or_pipeline)
          case name_or_pipeline
          when Pipeline::Extension
            name_or_pipeline.instance_variable_get(:@__pipeline)
          when Internal
            name_or_pipeline
          else
            @__pipelines.fetch(name_or_pipeline.to_sym) {
              raise ArgumentError, "could not find a pipeline named `#{name_or_pipeline}'"
            }
          end
        end
      end

      common_methods do
        # Defines an action on the current pipeline.
        #
        def action(action = nil, *args, before: nil, after: nil, **kwargs, &block)
          @__pipeline.action(action, *args, before: before, after: after, **kwargs, &block)
        end

        # Calls the pipeline with any given arguments.
        #
        def call(*args, **kwargs)
          @__pipeline.call(self, *args, **kwargs)
        end

        # Calls the pipeline in reverse order with any given arguments.
        #
        def rcall(*args, **kwargs)
          @__pipeline.rcall(self, *args, **kwargs)
        end
      end
    end
  end
end
