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

        def call(context, state, actions = @actions.dup)
          catch :halt do
            until actions.empty? || state.halted?
              catch :reject do
                actions.shift.call(context, state) do
                  call(context, state, actions)
                end
              end
            end
          end

          state.pipelined
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
