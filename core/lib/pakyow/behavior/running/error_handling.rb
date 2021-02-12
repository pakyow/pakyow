# frozen_string_literal: true

module Pakyow
  module Behavior
    module Running
      module ErrorHandling
        extend Support::Extension

        apply_extension do
          handle Exception do |error|
            case error
            when SystemExit
              # noop
            when SignalException
              raise error
            else
              handle_error(EnvironmentError.build(error))
            end
          end

          handle EnvironmentError do |error|
            handle_error(error)
          end

          handle ApplicationError do |error|
            error.context.rescue!(error)
          end
        end

        private def handle_error(error)
          Pakyow.rescue!(error)
        end
      end
    end
  end
end
