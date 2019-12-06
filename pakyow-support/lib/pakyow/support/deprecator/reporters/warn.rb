# frozen_string_literal: true

module Pakyow
  module Support
    class Deprecator
      module Reporters
        # Deprecation reporter that warns about deprecations.
        #
        # @example
        #   deprecator = Pakyow::Support::Deprecator.new(
        #     reporter: Pakyow::Support::Deprecator::Reporters::Warn
        #   )
        #
        #   deprecator.deprecated :foo, solution: "use `bar'"
        #   => warning: [deprecation] `foo' is deprecated; solution: use `bar'
        #
        class Warn
          def self.report
            warn "[deprecation] " + yield.to_s
          end
        end
      end
    end
  end
end
