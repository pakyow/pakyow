# frozen_string_literal: true

require_relative "class_state"
require_relative "deprecator"
require_relative "extension"

module Pakyow
  module Support
    # Provides pipeline behavior. Pipeline objects can define actions to be called in order on an
    # instance of the pipelined object. Each action can act on the object passed to it. Any action
    # can halt the pipeline, causing the result to be immediately returned without calling other
    # actions. Objects passed through the pipeline should include {Pipeline::Object}.
    #
    # See {Pakyow::Application} and {Pakyow::Routing::Controller} for more examples.
    #
    # @example
    #   class Application
    #     include Pakyow::Support::Pipeline
    #
    #     action :foo
    #     action :bar
    #
    #     def foo(result)
    #       result << "foo"
    #     end
    #
    #     def bar(result)
    #       result << "bar"
    #     end
    #   end
    #
    #   class Result
    #     include Pakyow::Support::Pipeline::Object
    #
    #     attr_reader :results
    #
    #     def initialize
    #       @results = []
    #     end
    #
    #     def <<(result)
    #       @results << result
    #     end
    #   end
    #
    #   Application.new.call(Result.new).results
    #   => ["foo", "bar"]
    #
    module Pipeline
      require "pakyow/support/pipeline/action"
      require "pakyow/support/pipeline/extension"
      require "pakyow/support/pipeline/internal"

      extend Support::Extension

      extend_dependency ClassState

      def self.extended(base)
        Pakyow::Support::Deprecator.global.deprecated "using `extend Pakyow::Support::Pipeline'", solution: "use `extend Pakyow::Support::Pipeline::Extension'"

        base.extend Pipeline::Extension
      end

      # @api private
      attr_reader :__pipeline

      def initialize_copy(_)
        @__pipeline = @__pipeline.dup

        super
      end

      apply_extension do
        class_state :__pipelines, default: {}, inheritable: true
        class_state :__pipeline, default: Internal.new(self), inheritable: true

        # Define a default pipeline.
        #
        pipeline :default do; end

        # Use the default pipeline so that actions can be defined immediately without ceremony.
        #
        use_pipeline :default
      end

      prepend_methods do
        def initialize(*)
          @__pipeline = self.class.__pipeline.dup

          super
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
        def action(action = nil, *options, before: nil, after: nil, &block)
          @__pipeline.action(action, *options, before: before, after: after, &block)
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
