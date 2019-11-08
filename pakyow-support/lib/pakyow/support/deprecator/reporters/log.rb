# frozen_string_literal: true

module Pakyow
  module Support
    class Deprecator
      module Reporters
        # Deprecation reporter that logs deprecations at the given level.
        #
        # @example
        #   Pakyow::Support::Deprecator.new(
        #     reporter: Pakyow::Support::Deprecator::Reporters::Log.new(
        #       logger: Pakyow.logger
        #     )
        #   )
        #
        #   deprecator.deprecated :foo, "use `bar'"
        #   => [deprecation] `foo' is deprecated; solution: use `bar'
        #
        class Log
          def initialize(logger:, level: :warn)
            @logger, @level = logger, level
          end

          # Reports deprecations through the logger.
          #
          def report
            @logger.public_send @level do
              "[deprecation] " + yield.to_s
            end
          end
        end
      end
    end
  end
end
