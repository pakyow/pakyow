# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Internal
        attr_reader :actions

        extend DeepFreeze
        insulate :context

        def initialize(context, &block)
          @actions = []
          @context = context

          if block_given?
            instance_exec(&block)
          end
        end

        def initialize_copy(_)
          @actions = @actions.map(&:dup)

          super
        end

        def call(context, *args, **kwargs)
          call_actions(context, *args, __actions: @actions.dup, **kwargs)
        end

        def rcall(context, *args, **kwargs)
          call_actions(context, *args, __actions: @actions.reverse, **kwargs)
        end

        def call_actions(context, *args, __actions:, **kwargs)
          Thread.current[:__pw_pipeline] ||= object_id

          finished = false

          catch :halt do
            until __actions.empty?
              catch :reject do
                __actions.shift.call(context, *args, **kwargs) do
                  call_actions(context, *args, __actions: __actions, **kwargs)
                end
              end
            end

            finished = true
          end

          unless finished || Thread.current[:__pw_pipeline] == object_id
            throw :halt
          end

          args.first
        ensure
          if Thread.current[:__pw_pipeline] == object_id
            Thread.current[:__pw_pipeline] = nil
          end
        end

        def action(target, *options, before: nil, after: nil, &block)
          Action.new(@context, target, *options, &block).tap do |action|
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

        # @api private
        def reset(context)
          @context = context
          @actions.each do |action|
            action.reset(context)
          end
        end
      end
    end
  end
end
