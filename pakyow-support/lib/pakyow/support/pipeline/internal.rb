# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
      # @api private
      class Internal
        attr_reader :actions

        def initialize(&block)
          @actions = []

          if block_given?
            instance_exec(&block)
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
    end
  end
end
