# frozen_string_literal: true

require_relative "../deep_freeze"

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
          call_actions(@actions.dup, context, *args, **kwargs)
        end

        def rcall(context, *args, **kwargs)
          call_actions(@actions.reverse, context, *args, **kwargs)
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

        private def call_actions(actions, context, *args, **kwargs)
          Thread.current[:__pw_pipeline] ||= object_id

          value = nil
          finished = false

          halted = catch :halt do
            value = call_each_action(actions, context, *args, **kwargs)

            finished = true
          end

          unless finished
            value = halted

            unless Thread.current[:__pw_pipeline] == object_id
              throw :halt, value
            end
          end

          value
        ensure
          if Thread.current[:__pw_pipeline] == object_id
            Thread.current[:__pw_pipeline] = nil
          end
        end

        private def call_each_action(actions, context, *args, **kwargs)
          value = nil
          finished = false

          until actions.empty?
            rejected = catch :reject do
              value = actions.shift.call(context, *args, **kwargs) do
                call_each_action(actions, context, *args, **kwargs)
              end

              finished = true
            end

            unless finished
              value = rejected
            end
          end

          value
        end
      end
    end
  end
end
