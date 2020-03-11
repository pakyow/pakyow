# frozen_string_literal: true

module Pakyow
  module Support
    module Pipeline
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
            until stack.empty? || object.halted?
              catch :reject do
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
          end

          object.pipelined
        end
      end
    end
  end
end
