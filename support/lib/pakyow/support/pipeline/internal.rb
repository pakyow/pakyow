# frozen_string_literal: true

require_relative "../deep_freeze"
require_relative "../thread_localizer"

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Internal
        attr_reader :actions

        include DeepFreeze
        insulate :context

        def initialize(context, &block)
          @actions = []
          @context = context

          if block
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

        def action(target, *options_args, before: nil, after: nil, **options_kwargs, &block)
          action = Action.new(@context, target, *options_args, **options_kwargs, &block)

          if before
            if (i = @actions.index { |a| a.name == before })
              @actions.insert(i, action)
            else
              @actions.unshift(action)
            end
          elsif after
            if (i = @actions.index { |a| a.name == after })
              @actions.insert(i + 1, action)
            else
              @actions << action
            end
          else
            @actions << action
          end

          action
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
          ThreadLocalizer.thread_localized_store[:__pw_pipeline_object_id] ||= object_id

          value = nil
          finished = false

          halted = catch(:__pipeline_halt) {
            value = call_each_action(actions, context, *args, **kwargs)

            finished = true
          }

          unless finished
            value = halted

            unless ThreadLocalizer.thread_localized_store[:__pw_pipeline_object_id] == object_id
              throw :__pipeline_halt, value
            end
          end

          value
        ensure
          if ThreadLocalizer.thread_localized_store[:__pw_pipeline_object_id] == object_id
            ThreadLocalizer.thread_localized_store.delete(:__pw_pipeline_object_id)
          end
        end

        private def call_each_action(actions, context, *args, **kwargs)
          value = nil
          finished = false

          until actions.empty?
            rejected = catch(:__pipeline_reject) {
              value = actions.shift.call(context, *args, **kwargs) {
                call_each_action(actions, context, *args, **kwargs)
              }

              finished = true
            }

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
