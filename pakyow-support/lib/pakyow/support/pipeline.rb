# frozen_string_literal: true

require "pakyow/support/class_state"

module Pakyow
  module Support
    # Provides pipeline behavior. Pipeline objects can define actions to be called in order on an
    # instance of the pipelined object. Each action can act on the state passed to it. Any action
    # can halt the pipeline, causing the result to be immediately returned without calling other
    # actions. State passed through the pipeline should include {Pipelined::Object}.
    #
    # See {Pakyow::App} and {Pakyow::Routing::Controller} for examples of more complex pipelines.
    #
    # @example
    #   class App
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
    #   App.new.call(Result.new).results
    #   => ["foo", "bar"]
    #
    # = Modules
    #
    # Pipeline behavior can be added to a module and then used in a pipelined object.
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
    #     include Pakyow::Support::Pipeline
    #
    #     use_pipeline VerifyRequest
    #
    #     ...
    #   end
    #
    module Pipeline
      # @api private
      def self.extended(base)
        base.extend ClassMethods
        base.extend ClassState unless base.ancestors.include?(ClassState)
        base.class_state :__pipelines, default: {}, inheritable: true
        base.class_state :__pipeline, inheritable: true

        base.instance_variable_set(:@__pipeline, Internal.new)
      end

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
        def initialize(*)
          @__pipeline = self.class.__pipeline.callable(self)
          super
        end
      end

      module ClassMethods
        # Defines a pipeline.
        #
        def pipeline(name, &block)
          @__pipelines[name.to_sym] = Internal.new(&block)
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
        def action(action = nil, *options, before: nil, after: nil, &block)
          @__pipeline.action(action, *options, before: before, after: after, &block)
        end

        def skip(*actions)
          @__pipeline.skip(*actions)
        end

        private

        def find_pipeline(name_or_pipeline)
          if name_or_pipeline.is_a?(Pipeline)
            name_or_pipeline.instance_variable_get(:@__pipeline)
          elsif name_or_pipeline.is_a?(Internal)
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

      # @api private
      class Internal
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
          Callable.new(@actions, context)
        end

        def action(target, *options, before: nil, after: nil, &block)
          Action.new(target, *options, &block).tap do |action|
            if before
              if i = @actions.index { |a| a.name == before }
                @actions.insert(i, action)
              else
                @actions.unshift(action)
              end
            elsif after
              if i = @actions.index { |a| a.name == after }
                @actions.insert(i + 1, action)
              else
                @actions << action
              end
            else
              @actions << action
            end
          end
        end

        def skip(*actions)
          @actions.delete_if { |action|
            actions.include?(action.name)
          }
        end

        def include_actions(actions)
          @actions.concat(actions).uniq!
        end

        def exclude_actions(actions)
          # Map input into a common denominator, to exclude both names and other action objects.
          targets = actions.map { |action|
            if action.is_a?(Action)
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
      class Callable
        def initialize(actions, context)
          @stack = actions.map { |action|
            action.finalize(context)
          }
        end

        def initialize_copy(_)
          @stack = @stack.dup

          super
        end

        def call(object, stack = @stack.dup)
          catch :halt do
            until stack.empty? || (object.respond_to?(:halted?) && object.halted?)
              action = stack.shift
              if action.arity == 0
                action.call do
                  call(object, stack)
                end
              else
                action.call(object) do
                  call(object, stack)
                end
              end
            end
          end

          object.pipelined
        end
      end

      # @api private
      class Action
        attr_reader :target, :name, :options

        def initialize(target, *options, &block)
          @target, @options, @block = target, options, block

          if target.is_a?(Symbol)
            @name = target
          end
        end

        def finalize(context = nil)
          if @block
            if context
              if @block.arity == 0
                Proc.new do
                  context.instance_exec(&@block)
                end
              else
                Proc.new do |object|
                  context.instance_exec(object, &@block)
                end
              end
            else
              @block
            end
          elsif @target.is_a?(Symbol) && context.respond_to?(@target, true)
            if context
              context.method(@target)
            else
              raise "finalizing pipeline action #{@target} requires context"
            end
          else
            target, target_options = if @target.is_a?(Symbol)
              [@options[0], @options[1..-1]]
            else
              [@target, @options]
            end

            instance = if target.is_a?(Class)
              target.new(*target_options)
            else
              target
            end

            instance.method(:call)
          end
        end
      end
    end
  end
end
