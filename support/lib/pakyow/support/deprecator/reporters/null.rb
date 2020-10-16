# frozen_string_literal: true

module Pakyow
  module Support
    class Deprecator
      module Reporters
        # Deprecation reporter that ignores reported deprecations.
        #
        # @example
        #   deprecator = Pakyow::Support::Deprecator.new(
        #     reporter: Pakyow::Support::Deprecator::Reporters::Null
        #   )
        #
        #   deprecator.deprecated :foo, solution: "use `bar'"
        #   # nothing happens
        #
        class Null
          # Eats the deprecation.
          #
          def self.report
          end
        end
      end
    end
  end
end
