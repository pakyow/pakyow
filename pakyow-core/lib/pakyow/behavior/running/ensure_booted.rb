# frozen_string_literal: true

require "pakyow/support/deep_freeze"

module Pakyow
  module Behavior
    module Running
      module EnsureBooted
        using Support::DeepFreeze

        # Call from a service to ensure that the environment has booted. Yields when booted.
        #
        private def ensure_booted
          unless Pakyow.booted? || Pakyow.rescued?
            Pakyow.boot(env: options[:env])

            Pakyow.deprecator.ignore do
              if Pakyow.config.freeze_on_boot
                Pakyow.deep_freeze
              end
            end
          end

          yield if Pakyow.booted? && !Pakyow.rescued?
        end
      end
    end
  end
end
