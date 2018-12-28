# frozen_string_literal: true

module Pakyow
  module Support
    # Provides pipeline behavior. Pipelined objects can define actions to be called in order on an
    # instance of the pipelined object. Each action can act on the state passed to it. Any action
    # can halt the pipeline, causing the result to be immediately returned without calling other
    # actions. Passed state should respond to `halt` and `halted?` (@see Pipelined::Haltable).
    #
    # See {Pakyow::App} and {Pakyow::Controller} for examples of more complex pipelines.
    #
    # @example
    #   class App
    #     include Pakyow::Support::Pipelined
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
    #     include Pakyow::Support::Pipelined::Haltable
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
    #   App.new.call(Result.new).results
    #   => ["foo", "bar"]
    #
    module Pipelined
      # @api private
      def self.included(base)
        base.extend ClassMethods
        base.extend ClassState unless base.ancestors.include?(ClassState)
        base.prepend Initializer
        base.class_state :__pipelines, default: {}, inheritable: true
        base.class_state :__pipeline, inheritable: true

        # Define a default pipeline so that actions can be defined immediately without ceremony.
        #
        base.pipeline :default do; end
        base.use_pipeline :default
      end

      # Calls the pipeline, passing +state+.
      #
      def call(state)
        @__pipeline.call(state)
      end

      def initialize_copy(_)
        super

        @__pipeline = @__pipeline.dup

        # rebind any methods to the new instance
        @__pipeline.instance_variable_get(:@stack).map! { |action|
          if action.is_a?(::Method) && action.receiver.is_a?(self.class)
            action.unbind.bind(self)
          else
            action
          end
        }
      end

      # @api private
      module Initializer
        def initialize(*args)
          @__pipeline = self.class.__pipeline.callable(self)
          super
        end
      end

      module ClassMethods
        # Defines a pipeline.
        #
        def pipeline(name, &block)
          @__pipelines[name.to_sym] = InternalPipeline.new(&block)
        end

        # Uses a pipeline.
        #
        def use_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          include name_or_pipeline if name_or_pipeline.is_a?(Pipeline)
          @__pipeline = pipeline
        end

        # Includes actions into the current pipeline.
        #
        def include_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          include name_or_pipeline if name_or_pipeline.is_a?(Pipeline)
          @__pipeline.include_actions(pipeline.actions)
        end

        # Excludes actions from the current pipeline.
        #
        def exclude_pipeline(name_or_pipeline)
          pipeline = find_pipeline(name_or_pipeline)
          @__pipeline.exclude_actions(pipeline.actions)
        end

        # Defines an action on the current pipeline.
        #
        def action(name, options = {}, &block)
          if block_given?
            define_method name, &block
            private name
          end

          @__pipeline.action(name, options, &block)
        end

        private

        def find_pipeline(name_or_pipeline)
          if name_or_pipeline.is_a?(Pipeline)
            name_or_pipeline.instance_variable_get(:@__pipeline)
          elsif name_or_pipeline.is_a?(InternalPipeline)
            name_or_pipeline
          else
            name_or_pipeline = name_or_pipeline.to_sym
            if @__pipelines.key?(name_or_pipeline)
              @__pipelines[name_or_pipeline]
            else
              raise ArgumentError, "could not find a pipeline named `#{name_or_pipeline}'"
            end
          end
        end
      end

      # Creates a pipeline that can be used or included in a pipelined object.
      #
      # @see Pipelined
      #
      # @example
      #   module VerifyRequest
      #     extend Pakyow::Support::Pipeline
      #
      #     action :verify_request
      #
      #     def verify_request
      #       ...
      #     end
      #   end
      #
      #   class App
      #     include Pakyow::Support::Pipelined
      #
      #     use_pipeline VerifyRequest
      #
      #     ...
      #   end
      #
      module Pipeline
        def self.extended(base)
          base.instance_variable_set(:@__pipeline, InternalPipeline.new)
        end

        attr_reader :__pipeline

        # Defines an action.
        # @see Pipelined::ClassMethods#action
        #
        def action(name, options = {})
          @__pipeline.action(name, options)
        end
      end

      # @api private
      class InternalPipeline
        attr_reader :actions

        def initialize
          @actions = []

          if block_given?
            instance_exec(&Proc.new)
          end
        end

        def initialize_copy(_)
          @actions = @actions.dup
          super
        end

        def callable(context)
          CallablePipeline.new(@actions, context)
        end

        def action(target, options = {})
          PipelineAction.new(target, options).tap do |action|
            @actions << action
          end
        end

        def include_actions(actions)
          @actions.concat(actions).uniq!
        end

        def exclude_actions(actions)
          # Map input into a common denominator, to exclude both names and other action objects.
          targets = actions.map { |action|
            if action.is_a?(PipelineAction)
              action.target
            else
              action
            end
          }

          @actions.delete_if { |action|
            targets.include?(action.target)
          }
        end
      end

      # @api private
      class CallablePipeline
        def initialize(actions, context)
          @stack = actions.map { |action|
            action.finalize(context)
          }
        end

        def initialize_copy(_)
          @stack = @stack.dup

          super
        end

        def call(object)
          catch :halt do
            @stack.each do |action|
              if action.arity == 0
                action.call
              else
                action.call(object)
              end

              break if object.respond_to?(:halted?) && object.halted?
            end
          end

          object
        end

        def action(target, options = {})
          @stack << PipelineAction.new(target, options).finalize
        end
      end

      # @api private
      class PipelineAction
        attr_reader :target, :options

        def initialize(target, options = {})
          @target, @options = target, options
        end

        def finalize(context = nil)
          if @target.is_a?(Symbol)
            if context
              context.method(@target)
            else
              raise "finalizing pipeline action #{@target} requires context"
            end
          else
            instance = if @target.is_a?(Class)
              @target.new(@options)
            else
              @target
            end

            instance.method(:call)
          end
        end
      end
    end
  end
end
